import React from 'react';
import { Box, Typography, Alert } from '@mui/material';

const NotificationCenter = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Notification Center
      </Typography>
      <Alert severity="info">
        Use the AI Chat tab for natural language notification commands like:
        "Send welcome email to john@company.com", "Show notification history", or "Send manager notification".
      </Alert>
    </Box>
  );
};

export default NotificationCenter;
