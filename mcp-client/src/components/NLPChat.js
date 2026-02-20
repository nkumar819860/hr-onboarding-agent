import React, { useState, useRef, useEffect } from 'react';
import {
  Box,
  Paper,
  TextField,
  Button,
  Typography,
  List,
  ListItem,
  ListItemText,
  Avatar,
  Chip,
  CircularProgress,
  Alert,
  Divider,
  Grid,
  Card,
  CardContent
} from '@mui/material';
import {
  Send as SendIcon,
  Person as PersonIcon,
  SmartToy as BotIcon,
  Psychology as PsychologyIcon
} from '@mui/icons-material';
import ReactMarkdown from 'react-markdown';
import { useGroqNLP } from '../services/groqService';
import { useMCPAggregator } from '../services/mcpAggregator';

const NLPChat = () => {
  const [messages, setMessages] = useState([
    {
      id: 1,
      type: 'bot',
      content: `Hello! 👋 I'm your HR Onboarding AI Assistant. I can help you with:

**Employee Management:**
- Create new employee records
- Search and view employee information
- Update employee details

**Asset Allocation:**
- Assign equipment to employees
- Check asset inventory
- Track asset allocations

**Notifications:**
- Send welcome emails
- Manager notifications
- IT setup requests

**Natural Language Commands:**
Try saying things like:
- "Create a new employee named John Smith in Engineering"
- "Allocate a laptop to employee ID 123"
- "Show me all employees in the Marketing department"
- "Send a welcome email to jane@company.com"

How can I help you today?`,
      timestamp: new Date(),
      aggregatedData: null
    }
  ]);
  
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef(null);
  
  const { processNaturalLanguage, isProcessing } = useGroqNLP();
  const { aggregateData, executeAction } = useMCPAggregator();

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = async () => {
    if (!input.trim() || isLoading) return;

    const userMessage = {
      id: Date.now(),
      type: 'user',
      content: input.trim(),
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      // Process natural language with Groq
      const nlpResult = await processNaturalLanguage(input.trim());
      
      let botResponse = {
        id: Date.now() + 1,
        type: 'bot',
        content: '',
        timestamp: new Date(),
        aggregatedData: null
      };

      if (nlpResult.intent && nlpResult.action) {
        // Execute MCP action based on intent
        const mcpResult = await executeAction(nlpResult.action, nlpResult.parameters);
        
        if (mcpResult.success) {
          // Get aggregated data for comprehensive response
          const aggregatedData = await aggregateData(nlpResult.intent, mcpResult.data);
          
          botResponse.content = generateResponse(nlpResult, mcpResult, aggregatedData);
          botResponse.aggregatedData = aggregatedData;
        } else {
          botResponse.content = `❌ **Error:** ${mcpResult.error}\n\nPlease try again or rephrase your request.`;
        }
      } else {
        // General conversation or help
        botResponse.content = nlpResult.response || "I'm not sure how to help with that. Could you please rephrase your request?";
      }

      setMessages(prev => [...prev, botResponse]);
    } catch (error) {
      console.error('Error processing message:', error);
      setMessages(prev => [...prev, {
        id: Date.now() + 1,
        type: 'bot',
        content: `❌ **System Error:** Unable to process your request. Please try again.\n\nError: ${error.message}`,
        timestamp: new Date(),
        aggregatedData: null
      }]);
    } finally {
      setIsLoading(false);
    }
  };

  const generateResponse = (nlpResult, mcpResult, aggregatedData) => {
    const { intent, action } = nlpResult;
    
    let response = `✅ **Success!** I've completed your request.\n\n`;
    
    switch (intent) {
      case 'create_employee':
        response += `**New Employee Created:**
- **Name:** ${mcpResult.data.name}
- **Email:** ${mcpResult.data.email}
- **Department:** ${mcpResult.data.department}
- **Employee ID:** ${mcpResult.data.id}

The employee has been added to the system and is ready for onboarding.`;
        break;
        
      case 'allocate_asset':
        response += `**Asset Allocated:**
- **Asset:** ${mcpResult.data.assetName}
- **Employee:** ${mcpResult.data.employeeName}
- **Allocation ID:** ${mcpResult.data.id}

The asset has been successfully assigned and logged.`;
        break;
        
      case 'send_notification':
        response += `**Notification Sent:**
- **Type:** ${mcpResult.data.type}
- **Recipient:** ${mcpResult.data.recipient}
- **Status:** ${mcpResult.data.status}

The notification has been processed and delivered.`;
        break;
        
      case 'get_employees':
        response += `**Employee Search Results:**
Found ${mcpResult.data.length} employee(s) matching your criteria.`;
        break;
        
      default:
        response += `Action completed successfully. Check the aggregated data below for details.`;
    }

    if (aggregatedData && aggregatedData.summary) {
      response += `\n\n**📊 System Summary:**\n${aggregatedData.summary}`;
    }

    return response;
  };

  const handleKeyPress = (event) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      handleSendMessage();
    }
  };

  const renderMessage = (message) => (
    <ListItem key={message.id} alignItems="flex-start" sx={{ px: 1, py: 1 }}>
      <Avatar sx={{ mr: 2, bgcolor: message.type === 'user' ? 'primary.main' : 'secondary.main' }}>
        {message.type === 'user' ? <PersonIcon /> : <BotIcon />}
      </Avatar>
      <Box sx={{ flexGrow: 1, maxWidth: '100%' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
          <Typography variant="subtitle2" sx={{ mr: 1 }}>
            {message.type === 'user' ? 'You' : 'AI Assistant'}
          </Typography>
          <Chip 
            size="small" 
            label={message.timestamp.toLocaleTimeString()} 
            variant="outlined" 
          />
        </Box>
        
        <Paper sx={{ p: 2, bgcolor: message.type === 'user' ? 'grey.100' : 'primary.50' }}>
          <ReactMarkdown>{message.content}</ReactMarkdown>
        </Paper>
        
        {message.aggregatedData && (
          <Box sx={{ mt: 2 }}>
            <Typography variant="subtitle2" gutterBottom>
              📊 Aggregated Data:
            </Typography>
            <Grid container spacing={2}>
              {Object.entries(message.aggregatedData).map(([key, value]) => (
                key !== 'summary' && (
                  <Grid item xs={12} sm={6} md={4} key={key}>
                    <Card variant="outlined" size="small">
                      <CardContent sx={{ p: 1, '&:last-child': { pb: 1 } }}>
                        <Typography variant="caption" color="textSecondary">
                          {key.toUpperCase()}
                        </Typography>
                        <Typography variant="body2">
                          {typeof value === 'object' ? JSON.stringify(value, null, 2) : String(value)}
                        </Typography>
                      </CardContent>
                    </Card>
                  </Grid>
                )
              ))}
            </Grid>
          </Box>
        )}
      </Box>
    </ListItem>
  );

  return (
    <Box sx={{ height: '80vh', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <Box sx={{ p: 2, bgcolor: 'primary.main', color: 'white', borderRadius: 1, mb: 2 }}>
        <Typography variant="h5" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
          <PsychologyIcon sx={{ mr: 1 }} />
          AI-Powered HR Assistant
        </Typography>
        <Typography variant="body2">
          Natural Language Processing with MCP Server Integration and Aggregated Responses
        </Typography>
      </Box>

      {/* Messages */}
      <Paper sx={{ flexGrow: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        <Box sx={{ flexGrow: 1, overflow: 'auto', p: 1 }}>
          <List>
            {messages.map(renderMessage)}
            {isLoading && (
              <ListItem>
                <Avatar sx={{ mr: 2, bgcolor: 'secondary.main' }}>
                  <BotIcon />
                </Avatar>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <CircularProgress size={20} sx={{ mr: 1 }} />
                  <Typography variant="body2" color="textSecondary">
                    AI is thinking...
                  </Typography>
                </Box>
              </ListItem>
            )}
          </List>
          <div ref={messagesEndRef} />
        </Box>

        <Divider />

        {/* Input */}
        <Box sx={{ p: 2 }}>
          <Box sx={{ display: 'flex', gap: 1 }}>
            <TextField
              fullWidth
              multiline
              maxRows={3}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="Type your message... (e.g., 'Create a new employee named John Smith')"
              disabled={isLoading || isProcessing}
              variant="outlined"
            />
            <Button
              variant="contained"
              onClick={handleSendMessage}
              disabled={!input.trim() || isLoading || isProcessing}
              sx={{ minWidth: 'auto', px: 2 }}
            >
              <SendIcon />
            </Button>
          </Box>
          
          {isProcessing && (
            <Alert severity="info" sx={{ mt: 1 }}>
              Processing natural language with Groq AI...
            </Alert>
          )}
        </Box>
      </Paper>
    </Box>
  );
};

export default NLPChat;
