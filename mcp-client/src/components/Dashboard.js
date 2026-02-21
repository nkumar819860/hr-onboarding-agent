import React, { useEffect, useState } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  CircularProgress,
  Alert,
  Chip
} from '@mui/material';
import {
  People as PeopleIcon,
  Laptop as LaptopIcon,
  Notifications as NotificationsIcon,
  LocalHospital as HealthIcon
} from '@mui/icons-material';
import { useMCPAggregator } from '../services/mcpAggregator';

const Dashboard = () => {
  const [systemHealth, setSystemHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const { checkSystemHealth } = useMCPAggregator();

  useEffect(() => {
    const loadDashboardData = async () => {
      try {
        const health = await checkSystemHealth();
        setSystemHealth(health);
      } catch (error) {
        console.error('Dashboard load error:', error);
      } finally {
        setLoading(false);
      }
    };

    loadDashboardData();
  }, [checkSystemHealth]);

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

  const getStatusText = (status) => {
    return status?.toUpperCase() || 'UNKNOWN';
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        HR Onboarding Dashboard
      </Typography>
      
      <Typography variant="body1" color="textSecondary" sx={{ mb: 3 }}>
        Monitor your HR onboarding system status and access AI-powered tools.
      </Typography>

      <Grid container spacing={3}>
        {/* System Health Cards */}
        <Grid item xs={12} sm={6} md={4}>
          <Card className="hover-card">
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <PeopleIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Employee MCP</Typography>
              </Box>
              <Chip 
                label={getStatusText(systemHealth?.employee?.status)}
                color={getStatusColor(systemHealth?.employee?.status)}
                size="small"
              />
              <Typography variant="body2" sx={{ mt: 1 }}>
                Manages employee records and HR data
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={4}>
          <Card className="hover-card">
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <LaptopIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Asset MCP</Typography>
              </Box>
              <Chip 
                label={getStatusText(systemHealth?.asset?.status)}
                color={getStatusColor(systemHealth?.asset?.status)}
                size="small"
              />
              <Typography variant="body2" sx={{ mt: 1 }}>
                Handles asset allocation and inventory
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} sm={6} md={4}>
          <Card className="hover-card">
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <NotificationsIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Notification MCP</Typography>
              </Box>
              <Chip 
                label={getStatusText(systemHealth?.notification?.status)}
                color={getStatusColor(systemHealth?.notification?.status)}
                size="small"
              />
              <Typography variant="body2" sx={{ mt: 1 }}>
                Manages notifications and communications
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        {/* Quick Actions */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <HealthIcon sx={{ mr: 1 }} />
                Quick Start Guide
              </Typography>
              
              <Alert severity="info" sx={{ mb: 2 }}>
                Welcome to the HR Onboarding Agent! Use the AI Chat tab to interact with the system using natural language.
              </Alert>

              <Typography variant="body2" sx={{ mb: 2 }}>
                <strong>Try these commands:</strong>
              </Typography>
              
              <Box component="ul" sx={{ pl: 2 }}>
                <li>
                  <Typography variant="body2">
                    "Create a new employee named John Smith in Engineering"
                  </Typography>
                </li>
                <li>
                  <Typography variant="body2">
                    "Allocate a laptop to employee ID 123"
                  </Typography>
                </li>
                <li>
                  <Typography variant="body2">
                    "Show me all employees in Marketing"
                  </Typography>
                </li>
                <li>
                  <Typography variant="body2">
                    "Send a welcome email to new@company.com"
                  </Typography>
                </li>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Environment Info */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Environment Information
              </Typography>
              
              <Grid container spacing={2}>
                <Grid item xs={12} sm={4}>
                  <Typography variant="body2" color="textSecondary">
                    Mode
                  </Typography>
                  <Typography variant="body1">
                    {process.env.NODE_ENV === 'development' ? 'Docker Development' : 'CloudHub Production'}
                  </Typography>
                </Grid>
                
                <Grid item xs={12} sm={4}>
                  <Typography variant="body2" color="textSecondary">
                    NLP Engine
                  </Typography>
                  <Typography variant="body1">
                    Groq LLaMA 3 8B
                  </Typography>
                </Grid>
                
                <Grid item xs={12} sm={4}>
                  <Typography variant="body2" color="textSecondary">
                    MCP Protocol
                  </Typography>
                  <Typography variant="body1">
                    2024-11-05
                  </Typography>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
