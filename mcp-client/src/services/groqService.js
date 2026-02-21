import { useState, useCallback } from 'react';
import Groq from 'groq-sdk';

// Environment configuration
const getEnvironmentConfig = () => {
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  return {
    groqApiKey: process.env.REACT_APP_GROQ_API_KEY || 'your-groq-api-key-here',
    employeeMcpUrl: isDevelopment 
      ? 'http://localhost:8081' 
      : process.env.REACT_APP_EMPLOYEE_MCP_URL || 'https://employee-onboarding-mcp-server-0etp45.rajrd4-2.usa-e1.cloudhub.io',
    assetMcpUrl: isDevelopment 
      ? 'http://localhost:8082' 
      : process.env.REACT_APP_ASSET_MCP_URL || 'https://asset-allocation-mcp-server-0etp45.rajrd4-1.usa-e1.cloudhub.io',
    notificationMcpUrl: isDevelopment 
      ? 'http://localhost:8083' 
      : process.env.REACT_APP_NOTIFICATION_MCP_URL || 'https://notification-mcp-server-0etp45.rajrd4-1.usa-e1.cloudhub.io'
  };
};

const config = getEnvironmentConfig();

// Initialize Groq client
const groq = new Groq({
  apiKey: config.groqApiKey,
  dangerouslyAllowBrowser: true // Note: In production, implement server-side proxy
});

// System prompt for HR onboarding context
const SYSTEM_PROMPT = `You are an AI assistant specializing in HR onboarding processes. You have access to three MCP servers:

1. **Employee MCP Server** - Manages employee records and HR data
2. **Asset MCP Server** - Handles asset allocation and inventory
3. **Notification MCP Server** - Manages communications and notifications

IMPORTANT: You must respond with a JSON object containing:
- intent: The user's intention (create_employee, allocate_asset, send_notification, get_employees, get_assets, etc.)
- action: The specific MCP action to execute
- parameters: The parameters needed for the action
- response: A helpful response to the user
- confidence: Your confidence level (0-1)

Available intents and actions:

**Employee Management:**
- Intent: create_employee
  Action: POST /mcp/tools/employees
  Parameters: {name, email, department, position, status}

- Intent: get_employees  
  Action: GET /mcp/tools/employees
  Parameters: {department?, status?, search?}

- Intent: get_employee
  Action: GET /mcp/tools/employees/{id}
  Parameters: {id}

- Intent: update_employee
  Action: PUT /mcp/tools/employees/{id}
  Parameters: {id, name?, email?, department?, position?, status?}

**Asset Management:**
- Intent: allocate_asset
  Action: POST /mcp/assets/allocate/{employeeId}
  Parameters: {employeeId, assetType, name, priority}

- Intent: get_employee_assets
  Action: GET /mcp/assets/employee/{employeeId}  
  Parameters: {employeeId}

- Intent: get_asset_inventory
  Action: GET /mcp/assets/inventory
  Parameters: {}

**Notifications:**
- Intent: send_notification
  Action: POST /mcp/notification/send-email
  Parameters: {to, subject, body}

- Intent: get_notification_history
  Action: GET /mcp/notification/history
  Parameters: {}

Parse user input and extract the intent, required parameters, and return appropriate JSON response.

Examples:
User: "Create a new employee named John Smith in Engineering"
Response: {
  "intent": "create_employee",
  "action": "POST /mcp/tools/employees",
  "parameters": {
    "name": "John Smith",
    "department": "Engineering",
    "email": "",
    "position": "",
    "status": "PENDING"
  },
  "response": "I'll create a new employee record for John Smith in the Engineering department.",
  "confidence": 0.9
}

User: "Show me all employees"
Response: {
  "intent": "get_employees",
  "action": "GET /mcp/tools/employees", 
  "parameters": {},
  "response": "I'll retrieve all employees for you.",
  "confidence": 0.95
}

Always respond in valid JSON format.`;

export const useGroqNLP = () => {
  const [isProcessing, setIsProcessing] = useState(false);

  const processNaturalLanguage = useCallback(async (userInput) => {
    setIsProcessing(true);
    
    try {
      const chatCompletion = await groq.chat.completions.create({
        messages: [
          {
            role: "system",
            content: SYSTEM_PROMPT
          },
          {
            role: "user", 
            content: userInput
          }
        ],
        model: "llama3-8b-8192", // Fast Groq model
        temperature: 0.1,
        max_tokens: 1024,
        response_format: { type: "json_object" }
      });

      const response = chatCompletion.choices[0]?.message?.content;
      
      if (!response) {
        throw new Error('No response from Groq API');
      }

      // Parse JSON response
      const parsedResponse = JSON.parse(response);
      
      // Validate response structure
      if (!parsedResponse.intent) {
        return {
          intent: null,
          action: null,
          parameters: {},
          response: "I'm not sure how to help with that. Could you please be more specific?",
          confidence: 0.1
        };
      }

      return parsedResponse;
      
    } catch (error) {
      console.error('Groq NLP Error:', error);
      
      // Fallback to rule-based parsing for common patterns
      return fallbackParsing(userInput);
    } finally {
      setIsProcessing(false);
    }
  }, []);

  // Fallback rule-based parsing for when Groq API fails
  const fallbackParsing = (input) => {
    const lowerInput = input.toLowerCase();
    
    // Employee creation patterns
    if (lowerInput.includes('create') && lowerInput.includes('employee')) {
      const nameMatch = input.match(/(?:named?|called)\s+([a-zA-Z\s]+?)(?:\s+in|\s+for|$)/i);
      const deptMatch = input.match(/(?:in|for|department)\s+([a-zA-Z\s]+)/i);
      
      return {
        intent: 'create_employee',
        action: 'POST /mcp/tools/employees',
        parameters: {
          name: nameMatch ? nameMatch[1].trim() : '',
          department: deptMatch ? deptMatch[1].trim() : '',
          email: '',
          position: '',
          status: 'PENDING'
        },
        response: 'I understand you want to create a new employee. I\'ll help you with that.',
        confidence: 0.7
      };
    }
    
    // Asset allocation patterns
    if ((lowerInput.includes('allocate') || lowerInput.includes('assign')) && 
        (lowerInput.includes('laptop') || lowerInput.includes('asset') || lowerInput.includes('equipment'))) {
      
      const assetMatch = input.match(/(laptop|computer|monitor|keyboard|mouse|phone)/i);
      const empIdMatch = input.match(/(?:employee|id|user)\s*(?:id\s*)?(\d+)/i);
      
      return {
        intent: 'allocate_asset',
        action: 'POST /mcp/assets/allocate/{employeeId}',
        parameters: {
          employeeId: empIdMatch ? empIdMatch[1] : '',
          assetType: assetMatch ? assetMatch[1].toLowerCase() : 'laptop',
          name: assetMatch ? assetMatch[1] : 'Standard Laptop',
          priority: 'medium'
        },
        response: 'I\'ll help you allocate that asset to the employee.',
        confidence: 0.6
      };
    }
    
    // Show/list employees patterns
    if ((lowerInput.includes('show') || lowerInput.includes('list') || lowerInput.includes('get')) && 
        lowerInput.includes('employee')) {
      
      return {
        intent: 'get_employees',
        action: 'GET /mcp/tools/employees',
        parameters: {},
        response: 'I\'ll retrieve the employee list for you.',
        confidence: 0.8
      };
    }
    
    // Default fallback
    return {
      intent: null,
      action: null,
      parameters: {},
      response: `I'm not sure how to help with "${input}". Try asking me to:
      
- Create a new employee
- Allocate assets to employees  
- Show employee lists
- Send notifications

For example: "Create a new employee named John Smith in Engineering"`,
      confidence: 0.1
    };
  };

  return {
    processNaturalLanguage,
    isProcessing
  };
};

// Enhanced NLP utilities
export const nlpUtils = {
  // Extract entities from text
  extractEntities: (text) => {
    const entities = {};
    
    // Extract names (capitalized words)
    const namePattern = /\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b/g;
    const names = text.match(namePattern) || [];
    if (names.length > 0) {
      entities.names = names;
    }
    
    // Extract email addresses
    const emailPattern = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g;
    const emails = text.match(emailPattern) || [];
    if (emails.length > 0) {
      entities.emails = emails;
    }
    
    // Extract numbers/IDs
    const numberPattern = /\b\d+\b/g;
    const numbers = text.match(numberPattern) || [];
    if (numbers.length > 0) {
      entities.numbers = numbers;
    }
    
    // Extract departments (common department names)
    const deptPattern = /\b(engineering|marketing|sales|finance|hr|human resources|it|operations|legal|admin)\b/gi;
    const departments = text.match(deptPattern) || [];
    if (departments.length > 0) {
      entities.departments = departments.map(d => d.toLowerCase());
    }
    
    return entities;
  },
  
  // Calculate intent confidence based on keywords
  calculateConfidence: (input, intent) => {
    const lowerInput = input.toLowerCase();
    
    const intentKeywords = {
      create_employee: ['create', 'add', 'new', 'employee', 'hire', 'onboard'],
      allocate_asset: ['allocate', 'assign', 'give', 'laptop', 'computer', 'equipment', 'asset'],
      get_employees: ['show', 'list', 'get', 'find', 'search', 'employees'],
      send_notification: ['send', 'email', 'notify', 'message', 'notification']
    };
    
    const keywords = intentKeywords[intent] || [];
    const matchCount = keywords.filter(keyword => lowerInput.includes(keyword)).length;
    
    return Math.min(matchCount / keywords.length, 1.0);
  }
};

export default useGroqNLP;
