# CloudHub Deployment Guide

This guide explains how to deploy the HR Onboarding Agent system to MuleSoft CloudHub using the automated deployment script.

## Prerequisites

### 1. Anypoint CLI v4 Installation
```bash
npm install -g @mulesoft/anypoint-cli-v4
```

### 2. Connected App Setup
You need to create a Connected App in Anypoint Platform with the following scopes:
- **Runtime Manager**: Read and Write access
- **CloudHub**: Read and Write access  
- **Design Center**: Read access (optional)
- **Exchange**: Read access (optional)

### 3. Maven Installation
Ensure Maven is installed and available in your PATH for building the applications.

## Configuration

### Step 1: Update Environment Variables

Edit the `.env` file and replace the placeholder values with your actual Anypoint Platform credentials:

```bash
# ========================================
# ANYPOINT CLI CONFIGURATION
# ========================================
ANYPOINT_CLIENT_ID=your-actual-connected-app-client-id
ANYPOINT_CLIENT_SECRET=your-actual-connected-app-client-secret
ANYPOINT_ORG_ID=your-actual-organization-id
ANYPOINT_ENV_NAME=Sandbox
ANYPOINT_BUSINESS_GROUP_ID=your-business-group-id

# CloudHub Deployment Configuration
CLOUDHUB_REGION=us-east-1
CLOUDHUB_WORKER_TYPE=MICRO
CLOUDHUB_WORKERS=1
CLOUDHUB_MULE_VERSION=4.5.4
```

### Step 2: Finding Your Anypoint Platform Details

#### Organization ID:
1. Log into Anypoint Platform
2. Go to **Access Management** → **Organization**
3. Copy the Organization ID from the URL or organization details

#### Connected App Credentials:
1. Go to **Access Management** → **Connected Apps**
2. Create a new Connected App or use existing one
3. Copy the **Client ID** and **Client Secret**

#### Environment Name:
- Default environments: `Sandbox`, `Production`
- Custom environments: Use the exact name as shown in Runtime Manager

## Deployment Process

### Option 1: Run the Batch Script (Windows)
```cmd
deploy-to-cloudhub.bat
```

### Option 2: Manual Step-by-Step Deployment

#### 1. Authenticate with Anypoint Platform
```bash
anypoint-cli-v4 login --client_id YOUR_CLIENT_ID --client_secret YOUR_CLIENT_SECRET --organization YOUR_ORG_ID
```

#### 2. Set Environment
```bash
anypoint-cli-v4 env use Sandbox
```

#### 3. Build Applications
```bash
# Employee Onboarding MCP
cd employee-onboarding-mcp
mvn clean package -DskipTests
cd ..

# Asset Allocation MCP
cd asset-allocation-mcp
mvn clean package -DskipTests
cd ..

# Notification MCP
cd notification-mcp
mvn clean package -DskipTests
cd ..

# Agent Fabric
cd agent-fabric
mvn clean package -DskipTests
cd ..
```

#### 4. Deploy to CloudHub
```bash
# Deploy Employee Onboarding MCP
anypoint-cli-v4 runtime-mgr cloudhub-application deploy \
    --runtime 4.5.4 \
    --workers 1 \
    --workerSize MICRO \
    --region us-east-1 \
    --property "http.port:8081" \
    --property "deployment.mode:cloud" \
    employee-onboarding-mcp-$(date +%Y%m%d-%H%M%S) \
    employee-onboarding-mcp/target/employee-onboarding-mcp-server-1.0.0-mule-application.jar

# Deploy Asset Allocation MCP
anypoint-cli-v4 runtime-mgr cloudhub-application deploy \
    --runtime 4.5.4 \
    --workers 1 \
    --workerSize MICRO \
    --region us-east-1 \
    --property "http.port:8082" \
    --property "deployment.mode:cloud" \
    asset-allocation-mcp-$(date +%Y%m%d-%H%M%S) \
    asset-allocation-mcp/target/asset-allocation-mcp-server-1.0.0-mule-application.jar

# Deploy Notification MCP
anypoint-cli-v4 runtime-mgr cloudhub-application deploy \
    --runtime 4.5.4 \
    --workers 1 \
    --workerSize MICRO \
    --region us-east-1 \
    --property "http.port:8083" \
    --property "deployment.mode:cloud" \
    notification-mcp-$(date +%Y%m%d-%H%M%S) \
    notification-mcp/target/notification-mcp-server-1.0.0-mule-application.jar

# Deploy Agent Fabric (with MCP URLs)
anypoint-cli-v4 runtime-mgr cloudhub-application deploy \
    --runtime 4.5.4 \
    --workers 1 \
    --workerSize MICRO \
    --region us-east-1 \
    --property "http.port:8080" \
    --property "https.port:8443" \
    --property "deployment.mode:cloud" \
    --property "employee.mcp.url:https://employee-onboarding-mcp-TIMESTAMP.us-east-1.cloudhub.io" \
    --property "asset.mcp.url:https://asset-allocation-mcp-TIMESTAMP.us-east-1.cloudhub.io" \
    --property "notification.mcp.url:https://notification-mcp-TIMESTAMP.us-east-1.cloudhub.io" \
    hr-onboarding-agent-$(date +%Y%m%d-%H%M%S) \
    agent-fabric/target/hr-onboarding-agent-fabric-1.0.0-mule-application.jar
```

## What the Script Does

### 1. Environment Validation
- Loads configuration from `.env` file
- Validates that all required credentials are configured
- Checks for Anypoint CLI v4 installation

### 2. Authentication
- Logs into Anypoint Platform using Connected App credentials
- Sets the target environment for deployment

### 3. Build Process
- Builds all four Mule applications using Maven
- Skips tests for faster deployment
- Validates successful compilation

### 4. CloudHub Deployment
- Deploys applications with unique timestamp-based names
- Configures runtime properties for cloud deployment
- Sets up inter-service communication URLs
- Uses Java 17 runtime specification

### 5. Results Summary
- Displays all deployed application URLs
- Shows available API endpoints
- Provides next steps for verification

## Application URLs After Deployment

After successful deployment, your applications will be available at:

```
Employee Onboarding MCP: https://employee-onboarding-mcp-{timestamp}.{region}.cloudhub.io
Asset Allocation MCP:    https://asset-allocation-mcp-{timestamp}.{region}.cloudhub.io  
Notification MCP:        https://notification-mcp-{timestamp}.{region}.cloudhub.io
HR Onboarding Agent:     https://hr-onboarding-agent-{timestamp}.{region}.cloudhub.io
```

## API Endpoints

### HR Onboarding Agent Fabric
- **Health Check**: `GET /agent/health`
- **Complete Onboarding**: `POST /agent/onboard`
- **Get Onboarding Status**: `GET /agent/onboard/{employeeId}/status`
- **List Employees**: `GET /agent/onboard/employees`

### MCP Servers
Each MCP server provides:
- **Health Check**: `GET /mcp/health`
- **API Documentation**: `GET /mcp/console`

## Testing the Deployment

### 1. Health Check
```bash
curl https://hr-onboarding-agent-{timestamp}.{region}.cloudhub.io/agent/health
```

### 2. Complete Onboarding Example
```bash
curl -X POST https://hr-onboarding-agent-{timestamp}.{region}.cloudhub.io/agent/onboard \
  -H "Content-Type: application/json" \
  -H "X-API-Key: hr-agent-secure-key-2024" \
  -d '{
    "employee": {
      "name": "John Doe",
      "email": "john.doe@company.com",
      "department": "Engineering",
      "position": "Software Developer",
      "manager_email": "manager@company.com"
    },
    "assets": [
      {
        "name": "Laptop",
        "type": "Hardware",
        "description": "MacBook Pro 16-inch"
      }
    ]
  }'
```

## Troubleshooting

### Common Issues

#### Authentication Failures
- Verify Connected App credentials in `.env` file
- Check that Connected App has proper scopes
- Ensure Organization ID is correct

#### Build Failures
- Check Maven installation: `mvn --version`
- Verify Java version compatibility
- Review build logs for specific error details

#### Deployment Failures
- Check CloudHub quotas and limits
- Verify environment permissions
- Review application names for conflicts

#### Runtime Issues
- Check application logs in Runtime Manager
- Verify all required properties are set
- Test inter-service connectivity

### Log Access
```bash
# View application logs
anypoint-cli-v4 runtime-mgr cloudhub-application logs hr-onboarding-agent-{timestamp}
```

### Application Management
```bash
# List deployed applications
anypoint-cli-v4 runtime-mgr cloudhub-application list

# Get application details
anypoint-cli-v4 runtime-mgr cloudhub-application describe hr-onboarding-agent-{timestamp}

# Restart application
anypoint-cli-v4 runtime-mgr cloudhub-application restart hr-onboarding-agent-{timestamp}
```

## Cleanup

To remove all deployed applications:
```bash
# List applications with timestamp pattern
anypoint-cli-v4 runtime-mgr cloudhub-application list | grep {timestamp}

# Delete individual applications
anypoint-cli-v4 runtime-mgr cloudhub-application delete employee-onboarding-mcp-{timestamp}
anypoint-cli-v4 runtime-mgr cloudhub-application delete asset-allocation-mcp-{timestamp}
anypoint-cli-v4 runtime-mgr cloudhub-application delete notification-mcp-{timestamp}
anypoint-cli-v4 runtime-mgr cloudhub-application delete hr-onboarding-agent-{timestamp}
```

## Support

For issues with:
- **CloudHub deployment**: Check MuleSoft documentation and support
- **Application functionality**: Review application logs and API responses
- **Integration issues**: Verify service connectivity and API keys
