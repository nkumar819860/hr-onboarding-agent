import React, { useState, useEffect } from 'react';
import { 
  ThemeProvider, 
  createTheme, 
  CssBaseline, 
  Container, 
  AppBar, 
  Toolbar, 
  Typography, 
  Box,
  Tab,
  Tabs,
  Paper
} from '@mui/material';
import { QueryClient, QueryClientProvider } from 'react-query';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';

import Dashboard from './components/Dashboard';
import EmployeeManagement from './components/EmployeeManagement';
import AssetManagement from './components/AssetManagement';
import NotificationCenter from './components/NotificationCenter';
import NLPChat from './components/NLPChat';
import SystemHealth from './components/SystemHealth';

// Create theme
const theme = createTheme({
  palette: {
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#f50057',
    },
    background: {
      default: '#f5f5f5',
    },
  },
  typography: {
    h4: {
      fontWeight: 600,
    },
  },
});

// Create React Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 2,
      refetchOnWindowFocus: false,
    },
  },
});

function TabPanel({ children, value, index, ...other }) {
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`tabpanel-${index}`}
      aria-labelledby={`tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ p: 3 }}>
          {children}
        </Box>
      )}
    </div>
  );
}

function MainContent() {
  const [tabValue, setTabValue] = useState(0);
  const location = useLocation();

  useEffect(() => {
    // Set tab based on route
    const path = location.pathname;
    if (path === '/employees') setTabValue(1);
    else if (path === '/assets') setTabValue(2);
    else if (path === '/notifications') setTabValue(3);
    else if (path === '/chat') setTabValue(4);
    else if (path === '/health') setTabValue(5);
    else setTabValue(0);
  }, [location]);

  const handleTabChange = (event, newValue) => {
    setTabValue(newValue);
  };

  return (
    <>
      <AppBar position="static" elevation={1}>
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            HR Onboarding Agent - MCP Client
          </Typography>
        </Toolbar>
      </AppBar>

      <Container maxWidth="xl" sx={{ mt: 2 }}>
        <Paper elevation={2}>
          <Tabs
            value={tabValue}
            onChange={handleTabChange}
            variant="scrollable"
            scrollButtons="auto"
            sx={{ borderBottom: 1, borderColor: 'divider' }}
          >
            <Tab label="Dashboard" />
            <Tab label="Employees" />
            <Tab label="Assets" />
            <Tab label="Notifications" />
            <Tab label="AI Chat" />
            <Tab label="System Health" />
          </Tabs>

          <TabPanel value={tabValue} index={0}>
            <Dashboard />
          </TabPanel>
          
          <TabPanel value={tabValue} index={1}>
            <EmployeeManagement />
          </TabPanel>
          
          <TabPanel value={tabValue} index={2}>
            <AssetManagement />
          </TabPanel>
          
          <TabPanel value={tabValue} index={3}>
            <NotificationCenter />
          </TabPanel>
          
          <TabPanel value={tabValue} index={4}>
            <NLPChat />
          </TabPanel>
          
          <TabPanel value={tabValue} index={5}>
            <SystemHealth />
          </TabPanel>
        </Paper>
      </Container>
    </>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Router>
          <Box sx={{ flexGrow: 1 }}>
            <Routes>
              <Route path="/*" element={<MainContent />} />
            </Routes>
          </Box>
        </Router>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;
