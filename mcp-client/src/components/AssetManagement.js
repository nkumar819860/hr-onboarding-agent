import React from 'react';
import { Box, Typography, Alert } from '@mui/material';

const AssetManagement = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Asset Management
      </Typography>
      <Alert severity="info">
        Use the AI Chat tab for natural language asset management commands like:
        "Allocate a laptop to employee 123", "Show asset inventory", or "Return asset ID 456".
      </Alert>
    </Box>
  );
};

export default AssetManagement;
