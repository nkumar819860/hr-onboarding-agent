import React from 'react';
import { Box, Typography, Alert } from '@mui/material';

const EmployeeManagement = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Employee Management
      </Typography>
      <Alert severity="info">
        Use the AI Chat tab for natural language employee management commands like:
        "Create a new employee", "Show all employees", or "Update employee information".
      </Alert>
    </Box>
  );
};

export default EmployeeManagement;
