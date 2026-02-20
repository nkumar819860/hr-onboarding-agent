import { useState, useCallback } from 'react';
import axios from 'axios';

// Environment configuration
const getEnvironmentConfig = () => {
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  return {
    employeeMcpUrl: isDevelopment 
      ? '/mcp/employee' // Proxied through nginx in Docker
      : process.env.REACT_APP_EMPLOYEE_MCP_URL || 'https://employee-onboarding-mcp-server-0etp45.rajrd4-2.usa-e1.cloudhub.io/mcp',
    assetMcpUrl: isDevelopment 
      ? '/mcp/asset' // Proxied through nginx in Docker
      : process.env.REACT_APP_ASSET_MCP_URL || 'https://asset-allocation-mcp-server-0etp45.rajrd4-1.usa-e1.cloudhub.io/mcp',
    notificationMcpUrl: isDevelopment 
      ? '/mcp/notification' // Proxied through nginx in Docker
      : process.env.REACT_APP_NOTIFICATION_MCP_URL || 'https://notification-mcp-server-0etp45.rajrd4-1.usa-e1.cloudhub.io/mcp'
  };
};

const config = getEnvironmentConfig();

// Create axios instances for each MCP server
const createAxiosInstance = (baseURL) => {
  return axios.create({
    baseURL,
    timeout: 10000,
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': 'hr-agent-secure-key-2024' // Should match your MCP server config
    }
  });
};

const employeeAPI = createAxiosInstance(config.employeeMcpUrl);
const assetAPI = createAxiosInstance(config.assetMcpUrl);
const notificationAPI = createAxiosInstance(config.notificationMcpUrl);

// Add response interceptors for error handling
[employeeAPI, assetAPI, notificationAPI].forEach(api => {
  api.interceptors.response.use(
    (response) => response,
    (error) => {
      console.error('MCP API Error:', error);
      return Promise.reject(error);
    }
  );
});

export const useMCPAggregator = () => {
  const [isLoading, setIsLoading] = useState(false);

  // Execute MCP actions based on NLP intent
  const executeAction = useCallback(async (action, parameters) => {
    setIsLoading(true);
    
    try {
      const [method, endpoint] = action.split(' ');
      let result;

      switch (true) {
        // Employee Management Actions
        case endpoint.includes('/mcp/tools/employees'):
          result = await executeEmployeeAction(method, endpoint, parameters);
          break;

        // Asset Management Actions  
        case endpoint.includes('/mcp/assets/'):
          result = await executeAssetAction(method, endpoint, parameters);
          break;

        // Notification Actions
        case endpoint.includes('/mcp/notification/'):
          result = await executeNotificationAction(method, endpoint, parameters);
          break;

        default:
          throw new Error(`Unknown action: ${action}`);
      }

      return { success: true, data: result };
      
    } catch (error) {
      console.error('Action execution error:', error);
      return { 
        success: false, 
        error: error.response?.data?.message || error.message || 'Unknown error occurred'
      };
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Employee MCP actions
  const executeEmployeeAction = async (method, endpoint, parameters) => {
    switch (method) {
      case 'POST':
        if (endpoint.includes('/employees')) {
          const response = await employeeAPI.post('/tools/employees', {
            name: parameters.name || 'New Employee',
            email: parameters.email || `${(parameters.name || 'employee').toLowerCase().replace(/\s+/g, '.')}@company.com`,
            department: parameters.department || 'General',
            position: parameters.position || 'Employee',
            status: parameters.status || 'PENDING'
          });
          return response.data;
        }
        break;

      case 'GET':
        if (endpoint.includes('/employees/{id}')) {
          const response = await employeeAPI.get(`/tools/employees/${parameters.id}`);
          return response.data;
        } else if (endpoint.includes('/employees')) {
          const queryParams = new URLSearchParams();
          if (parameters.department) queryParams.append('department', parameters.department);
          if (parameters.status) queryParams.append('status', parameters.status);
          if (parameters.search) queryParams.append('search', parameters.search);
          
          const response = await employeeAPI.get(`/tools/employees?${queryParams.toString()}`);
          return response.data;
        }
        break;

      case 'PUT':
        if (endpoint.includes('/employees/{id}')) {
          const response = await employeeAPI.put(`/tools/employees/${parameters.id}`, parameters);
          return response.data;
        }
        break;

      default:
        throw new Error(`Unsupported employee action: ${method} ${endpoint}`);
    }
  };

  // Asset MCP actions
  const executeAssetAction = async (method, endpoint, parameters) => {
    switch (method) {
      case 'POST':
        if (endpoint.includes('/allocate/')) {
          const employeeId = parameters.employeeId || extractIdFromEndpoint(endpoint);
          const response = await assetAPI.post(`/assets/allocate/${employeeId}`, {
            assetType: parameters.assetType || 'laptop',
            name: parameters.name || 'Standard Asset',
            priority: parameters.priority || 'medium'
          });
          return response.data;
        }
        break;

      case 'GET':
        if (endpoint.includes('/employee/')) {
          const employeeId = parameters.employeeId || extractIdFromEndpoint(endpoint);
          const response = await assetAPI.get(`/assets/employee/${employeeId}`);
          return response.data;
        } else if (endpoint.includes('/inventory')) {
          const response = await assetAPI.get('/assets/inventory');
          return response.data;
        }
        break;

      default:
        throw new Error(`Unsupported asset action: ${method} ${endpoint}`);
    }
  };

  // Notification MCP actions
  const executeNotificationAction = async (method, endpoint, parameters) => {
    switch (method) {
      case 'POST':
        if (endpoint.includes('/send-email')) {
          const response = await notificationAPI.post('/notification/send-email', {
            to: parameters.to || 'employee@company.com',
            subject: parameters.subject || 'HR Notification',
            body: parameters.body || 'This is an automated HR notification.'
          });
          return response.data;
        }
        break;

      case 'GET':
        if (endpoint.includes('/history')) {
          const response = await notificationAPI.get('/notification/history');
          return response.data;
        }
        break;

      default:
        throw new Error(`Unsupported notification action: ${method} ${endpoint}`);
    }
  };

  // Aggregate data from multiple MCP servers for comprehensive responses
  const aggregateData = useCallback(async (intent, primaryData) => {
    try {
      const aggregatedData = {
        primary: primaryData,
        summary: ''
      };

      // Get health status from all MCP servers
      const healthPromises = [
        employeeAPI.get('/health').catch(() => ({ data: { status: 'unhealthy' } })),
        assetAPI.get('/health').catch(() => ({ data: { status: 'unhealthy' } })),
        notificationAPI.get('/health').catch(() => ({ data: { status: 'unhealthy' } }))
      ];

      const [employeeHealth, assetHealth, notificationHealth] = await Promise.all(healthPromises);

      aggregatedData.systemHealth = {
        employee: employeeHealth.data?.status || 'unknown',
        asset: assetHealth.data?.status || 'unknown',
        notification: notificationHealth.data?.status || 'unknown'
      };

      // Aggregate contextual data based on intent
      switch (intent) {
        case 'create_employee':
          // Get total employee count and department stats
          try {
            const employeesResponse = await employeeAPI.get('/tools/employees');
            const employees = employeesResponse.data.employees || [];
            
            aggregatedData.employeeStats = {
              total: employees.length,
              byDepartment: groupByDepartment(employees),
              recentlyAdded: employees.filter(emp => 
                new Date(emp.createdAt) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
              ).length
            };

            aggregatedData.summary = `Employee created successfully. Total employees: ${employees.length}. Department distribution available in stats.`;
          } catch (error) {
            console.warn('Could not fetch employee stats:', error);
          }
          break;

        case 'allocate_asset':
          // Get asset inventory and allocation stats
          try {
            const inventoryResponse = await assetAPI.get('/assets/inventory');
            const inventory = inventoryResponse.data || {};
            
            aggregatedData.assetStats = {
              inventory: inventory,
              totalAllocated: Object.values(inventory).reduce((sum, count) => sum + (count?.allocated || 0), 0),
              totalAvailable: Object.values(inventory).reduce((sum, count) => sum + (count?.available || 0), 0)
            };

            aggregatedData.summary = `Asset allocated successfully. Current inventory status and allocation stats available.`;
          } catch (error) {
            console.warn('Could not fetch asset stats:', error);
          }
          break;

        case 'get_employees':
          // Enrich employee data with asset allocations
          try {
            const employees = Array.isArray(primaryData) ? primaryData : primaryData.employees || [];
            
            // Get asset allocations for employees (limit to first 10 for performance)
            const assetPromises = employees.slice(0, 10).map(async (emp) => {
              try {
                const assetsResponse = await assetAPI.get(`/assets/employee/${emp.id}`);
                return { employeeId: emp.id, assets: assetsResponse.data || [] };
              } catch {
                return { employeeId: emp.id, assets: [] };
              }
            });

            const assetAllocations = await Promise.all(assetPromises);
            aggregatedData.assetAllocations = assetAllocations;

            aggregatedData.summary = `Found ${employees.length} employees. Asset allocation data included for recent employees.`;
          } catch (error) {
            console.warn('Could not fetch asset allocations:', error);
          }
          break;

        case 'send_notification':
          // Get recent notification history
          try {
            const historyResponse = await notificationAPI.get('/notification/history');
            const notifications = historyResponse.data || [];
            
            aggregatedData.notificationStats = {
              totalSent: notifications.length,
              recentCount: notifications.filter(notif => 
                new Date(notif.createdAt) > new Date(Date.now() - 24 * 60 * 60 * 1000)
              ).length,
              successRate: notifications.length > 0 ? 
                (notifications.filter(n => n.status === 'SENT').length / notifications.length) * 100 : 0
            };

            aggregatedData.summary = `Notification sent successfully. Recent notification statistics included.`;
          } catch (error) {
            console.warn('Could not fetch notification stats:', error);
          }
          break;

        default:
          aggregatedData.summary = 'Action completed successfully.';
      }

      // Add timestamp
      aggregatedData.timestamp = new Date().toISOString();
      
      return aggregatedData;

    } catch (error) {
      console.error('Error aggregating data:', error);
      return {
        primary: primaryData,
        summary: 'Action completed successfully, but some additional data could not be retrieved.',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }, []);

  // Utility functions
  const extractIdFromEndpoint = (endpoint) => {
    const match = endpoint.match(/\/(\d+)(?:$|\?)/);
    return match ? match[1] : null;
  };

  const groupByDepartment = (employees) => {
    return employees.reduce((acc, emp) => {
      const dept = emp.department || 'Unknown';
      acc[dept] = (acc[dept] || 0) + 1;
      return acc;
    }, {});
  };

  // Health check utilities
  const checkSystemHealth = useCallback(async () => {
    try {
      const healthChecks = await Promise.allSettled([
        employeeAPI.get('/health'),
        assetAPI.get('/health'), 
        notificationAPI.get('/health')
      ]);

      return {
        employee: healthChecks[0].status === 'fulfilled' ? healthChecks[0].value.data : { status: 'unhealthy', error: healthChecks[0].reason?.message },
        asset: healthChecks[1].status === 'fulfilled' ? healthChecks[1].value.data : { status: 'unhealthy', error: healthChecks[1].reason?.message },
        notification: healthChecks[2].status === 'fulfilled' ? healthChecks[2].value.data : { status: 'unhealthy', error: healthChecks[2].reason?.message }
      };
    } catch (error) {
      console.error('Health check error:', error);
      return {
        employee: { status: 'unknown', error: error.message },
        asset: { status: 'unknown', error: error.message },
        notification: { status: 'unknown', error: error.message }
      };
    }
  }, []);

  return {
    executeAction,
    aggregateData,
    checkSystemHealth,
    isLoading
  };
};

// Direct API utilities for individual components
export const mcpAPI = {
  employee: employeeAPI,
  asset: assetAPI,
  notification: notificationAPI
};

export default useMCPAggregator;
