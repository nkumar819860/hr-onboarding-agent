import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Chip,
  Button,
  CircularProgress,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  LinearProgress,
  Alert,
  Switch,
  FormControlLabel,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Badge,
  Tooltip,
  IconButton
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
  Memory as MemoryIcon,
  Speed as SpeedIcon,
  Storage as StorageIcon,
  Timeline as TimelineIcon,
  Notifications as NotificationsIcon,
  Autorenew as AutorenewIcon,
  InfoOutlined as InfoIcon
} from '@mui/icons-material';
import { useMCPAggregator, mcpAPI } from '../services/mcpAggregator';

const SystemHealth = () => {
  const [healthData, setHealthData] = useState(null);
  const [systemMetrics, setSystemMetrics] = useState(null);
  const [performanceData, setPerformanceData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [autoRefresh, setAutoRefresh] = useState(false);
  const [lastUpdated, setLastUpdated] = useState(null);
  const [alerts, setAlerts] = useState([]);
  const { checkSystemHealth } = useMCPAggregator();

  const loadHealthData = useCallback(async () => {
    setLoading(true);
    try {
      const startTime = Date.now();
      
      // Get health status from all services
      const health = await checkSystemHealth();
      setHealthData(health);

      // Simulate system metrics (in a real app, these would come from monitoring APIs)
      const metrics = await loadSystemMetrics();
      setSystemMetrics(metrics);

      // Calculate response times
      const responseTime = Date.now() - startTime;
      const newPerformanceEntry = {
        timestamp: new Date().toISOString(),
        responseTime,
        services: Object.keys(health).length,
        healthyServices: Object.values(health).filter(s => s.status === 'healthy').length
      };

      setPerformanceData(prev => [...prev.slice(-19), newPerformanceEntry]);
      
      // Generate alerts based on health data
      const newAlerts = generateAlerts(health, metrics);
      setAlerts(newAlerts);

      setLastUpdated(new Date());
    } catch (error) {
      console.error('Health check error:', error);
      setAlerts(prev => [...prev, {
        id: Date.now(),
        type: 'error',
        message: `Health check failed: ${error.message}`,
        timestamp: new Date()
      }]);
    } finally {
      setLoading(false);
    }
  }, [checkSystemHealth]);

  const loadSystemMetrics = async () => {
    // Simulate system metrics - in production, these would come from actual monitoring
    return {
      cpu: {
        usage: Math.random() * 100,
        cores: 4,
        load: Math.random() * 4
      },
      memory: {
        used: Math.random() * 8192,
        total: 16384,
        cached: Math.random() * 2048
      },
      disk: {
        used: Math.random() * 100,
        total: 500,
        readOps: Math.floor(Math.random() * 1000),
        writeOps: Math.floor(Math.random() * 500)
      },
      network: {
        bytesIn: Math.floor(Math.random() * 1000000),
        bytesOut: Math.floor(Math.random() * 500000),
        connections: Math.floor(Math.random() * 100)
      }
    };
  };

  const generateAlerts = (health, metrics) => {
    const alerts = [];
    
    // Check service health
    Object.entries(health).forEach(([service, data]) => {
      if (data.status !== 'healthy' && data.status !== 'up') {
        alerts.push({
          id: `${service}-${Date.now()}`,
          type: 'error',
          message: `${service.toUpperCase()} MCP service is ${data.status}`,
          timestamp: new Date(),
          service
        });
      }
    });

    // Check system metrics
    if (metrics) {
      if (metrics.cpu.usage > 90) {
        alerts.push({
          id: `cpu-${Date.now()}`,
          type: 'warning',
          message: `High CPU usage: ${metrics.cpu.usage.toFixed(1)}%`,
          timestamp: new Date()
        });
      }

      if (metrics.memory.used / metrics.memory.total > 0.9) {
        alerts.push({
          id: `memory-${Date.now()}`,
          type: 'warning',
          message: `High memory usage: ${((metrics.memory.used / metrics.memory.total) * 100).toFixed(1)}%`,
          timestamp: new Date()
        });
      }

      if (metrics.disk.used / metrics.disk.total > 0.9) {
        alerts.push({
          id: `disk-${Date.now()}`,
          type: 'warning',
          message: `Low disk space: ${((metrics.disk.used / metrics.disk.total) * 100).toFixed(1)}% used`,
          timestamp: new Date()
        });
      }
    }

    return alerts;
  };

  useEffect(() => {
    loadHealthData();
  }, [loadHealthData]);

  useEffect(() => {
    let interval;
    if (autoRefresh) {
      interval = setInterval(() => {
        loadHealthData();
      }, 30000); // Refresh every 30 seconds
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [autoRefresh, loadHealthData]);

  const getStatusIcon = (status) => {
    switch (status?.toLowerCase()) {
      case 'up':
      case 'healthy':
        return <CheckCircleIcon color="success" />;
      case 'down':
      case 'unhealthy':
        return <ErrorIcon color="error" />;
      default:
        return <WarningIcon color="warning" />;
    }
  };

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'up':
      case 'healthy':
        return 'success';
      case 'down':
      case 'unhealthy':
        return 'error';
      default:
        return 'warning';
    }
  };

  const formatBytes = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const getHealthScore = () => {
    if (!healthData) return 0;
    const services = Object.values(healthData);
    const healthyCount = services.filter(s => s.status === 'healthy' || s.status === 'up').length;
    return Math.round((healthyCount / services.length) * 100);
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4">
            System Health Monitor
          </Typography>
          {lastUpdated && (
            <Typography variant="caption" color="text.secondary">
              Last updated: {lastUpdated.toLocaleTimeString()}
            </Typography>
          )}
        </Box>
        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
          <FormControlLabel
            control={
              <Switch
                checked={autoRefresh}
                onChange={(e) => setAutoRefresh(e.target.checked)}
                icon={<AutorenewIcon />}
                checkedIcon={<AutorenewIcon />}
              />
            }
            label="Auto Refresh"
          />
          <Button
            variant="contained"
            startIcon={loading ? <CircularProgress size={16} /> : <RefreshIcon />}
            onClick={loadHealthData}
            disabled={loading}
          >
            Refresh Status
          </Button>
        </Box>
      </Box>

      {/* Alerts Section */}
      {alerts.length > 0 && (
        <Box sx={{ mb: 3 }}>
          {alerts.slice(0, 3).map((alert) => (
            <Alert 
              key={alert.id} 
              severity={alert.type} 
              sx={{ mb: 1 }}
              action={
                <Tooltip title="Alert details">
                  <IconButton size="small">
                    <InfoIcon />
                  </IconButton>
                </Tooltip>
              }
            >
              {alert.message}
            </Alert>
          ))}
        </Box>
      )}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
          <CircularProgress />
        </Box>
      ) : (
        <Grid container spacing={3}>
          {/* Overall Health Score */}
          <Grid item xs={12} md={3}>
            <Card>
              <CardContent sx={{ textAlign: 'center' }}>
                <Typography variant="h6" gutterBottom>
                  Overall Health
                </Typography>
                <Box sx={{ position: 'relative', display: 'inline-flex' }}>
                  <CircularProgress
                    variant="determinate"
                    value={getHealthScore()}
                    size={80}
                    thickness={4}
                    color={getHealthScore() > 80 ? 'success' : getHealthScore() > 60 ? 'warning' : 'error'}
                  />
                  <Box
                    sx={{
                      top: 0,
                      left: 0,
                      bottom: 0,
                      right: 0,
                      position: 'absolute',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <Typography variant="h6" color="text.secondary">
                      {getHealthScore()}%
                    </Typography>
                  </Box>
                </Box>
                <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                  {healthData && Object.keys(healthData).length} Services Monitored
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          {/* System Metrics Cards */}
          {systemMetrics && (
            <>
              <Grid item xs={12} md={3}>
                <Card>
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <MemoryIcon color="primary" sx={{ mr: 1 }} />
                      <Typography variant="h6">CPU Usage</Typography>
                    </Box>
                    <Typography variant="h4" color="primary">
                      {systemMetrics.cpu.usage.toFixed(1)}%
                    </Typography>
                    <LinearProgress
                      variant="determinate"
                      value={systemMetrics.cpu.usage}
                      color={systemMetrics.cpu.usage > 80 ? 'error' : 'primary'}
                      sx={{ mt: 1 }}
                    />
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                      {systemMetrics.cpu.cores} cores • Load: {systemMetrics.cpu.load.toFixed(2)}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>

              <Grid item xs={12} md={3}>
                <Card>
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <SpeedIcon color="secondary" sx={{ mr: 1 }} />
                      <Typography variant="h6">Memory</Typography>
                    </Box>
                    <Typography variant="h4" color="secondary">
                      {((systemMetrics.memory.used / systemMetrics.memory.total) * 100).toFixed(1)}%
                    </Typography>
                    <LinearProgress
                      variant="determinate"
                      value={(systemMetrics.memory.used / systemMetrics.memory.total) * 100}
                      color={(systemMetrics.memory.used / systemMetrics.memory.total) > 0.8 ? 'error' : 'secondary'}
                      sx={{ mt: 1 }}
                    />
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                      {formatBytes(systemMetrics.memory.used * 1024 * 1024)} / {formatBytes(systemMetrics.memory.total * 1024 * 1024)}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>

              <Grid item xs={12} md={3}>
                <Card>
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <StorageIcon color="success" sx={{ mr: 1 }} />
                      <Typography variant="h6">Disk Usage</Typography>
                    </Box>
                    <Typography variant="h4" color="success">
                      {((systemMetrics.disk.used / systemMetrics.disk.total) * 100).toFixed(1)}%
                    </Typography>
                    <LinearProgress
                      variant="determinate"
                      value={(systemMetrics.disk.used / systemMetrics.disk.total) * 100}
                      color={(systemMetrics.disk.used / systemMetrics.disk.total) > 0.9 ? 'error' : 'success'}
                      sx={{ mt: 1 }}
                    />
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                      {systemMetrics.disk.used.toFixed(1)} GB / {systemMetrics.disk.total} GB
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            </>
          )}

          {/* Service Health Status Cards */}
          {healthData && Object.entries(healthData).map(([service, data]) => (
            <Grid item xs={12} md={4} key={service}>
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                    <Typography variant="h6" sx={{ textTransform: 'capitalize' }}>
                      {service} MCP
                    </Typography>
                    <Badge
                      color={getStatusColor(data.status)}
                      variant="dot"
                      sx={{ '& .MuiBadge-dot': { 
                        animation: data.status === 'healthy' || data.status === 'up' 
                          ? 'pulse 2s infinite' : 'none' 
                      } }}
                    >
                      <Chip
                        icon={getStatusIcon(data.status)}
                        label={data.status?.toUpperCase() || 'UNKNOWN'}
                        color={getStatusColor(data.status)}
                        variant="outlined"
                      />
                    </Badge>
                  </Box>
                  
                  <List dense>
                    <ListItem>
                      <ListItemIcon>
                        {getStatusIcon(data.status)}
                      </ListItemIcon>
                      <ListItemText
                        primary="Service Status"
                        secondary={data.status || 'Unknown'}
                      />
                    </ListItem>
                    
                    {data.version && (
                      <ListItem>
                        <ListItemText
                          primary="Version"
                          secondary={data.version}
                        />
                      </ListItem>
                    )}
                    
                    {data.database && (
                      <ListItem>
                        <ListItemText
                          primary="Database"
                          secondary={data.database}
                        />
                      </ListItem>
                    )}
                    
                    {data.responseTime && (
                      <ListItem>
                        <ListItemText
                          primary="Response Time"
                          secondary={`${data.responseTime}ms`}
                        />
                      </ListItem>
                    )}
                    
                    {data.error && (
                      <ListItem>
                        <ListItemIcon>
                          <ErrorIcon color="error" />
                        </ListItemIcon>
                        <ListItemText
                          primary="Error"
                          secondary={data.error}
                        />
                      </ListItem>
                    )}
                  </List>
                </CardContent>
              </Card>
            </Grid>
          ))}

          {/* Performance History */}
          {performanceData.length > 0 && (
            <Grid item xs={12}>
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                    <TimelineIcon color="info" sx={{ mr: 1 }} />
                    <Typography variant="h6">Performance History</Typography>
                  </Box>
                  <TableContainer component={Paper} variant="outlined">
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Time</TableCell>
                          <TableCell align="right">Response Time (ms)</TableCell>
                          <TableCell align="right">Services</TableCell>
                          <TableCell align="right">Healthy</TableCell>
                          <TableCell align="right">Health Score</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {performanceData.slice(-10).reverse().map((entry, index) => (
                          <TableRow key={index}>
                            <TableCell>
                              {new Date(entry.timestamp).toLocaleTimeString()}
                            </TableCell>
                            <TableCell align="right">
                              <Chip
                                label={entry.responseTime}
                                size="small"
                                color={entry.responseTime > 1000 ? 'error' : entry.responseTime > 500 ? 'warning' : 'success'}
                                variant="outlined"
                              />
                            </TableCell>
                            <TableCell align="right">{entry.services}</TableCell>
                            <TableCell align="right">{entry.healthyServices}</TableCell>
                            <TableCell align="right">
                              {Math.round((entry.healthyServices / entry.services) * 100)}%
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                </CardContent>
              </Card>
            </Grid>
          )}
        </Grid>
      )}

      {/* Pulse animation styles */}
      <style jsx>{`
        @keyframes pulse {
          0% {
            opacity: 1;
          }
          50% {
            opacity: 0.5;
          }
          100% {
            opacity: 1;
          }
        }
      `}</style>
    </Box>
  );
};

export default SystemHealth;
