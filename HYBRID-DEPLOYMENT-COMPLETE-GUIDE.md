# Complete Hybrid Deployment Guide for HR Onboarding Agent

This comprehensive guide addresses Connected App authentication issues and provides multiple deployment strategies using Anypoint CLI for authentication and Maven for building.

## Current Status

✅ **WORKING COMPONENTS:**
- Maven build system (tested successfully)
- All Mule applications compile without errors
- Anypoint CLI v4 is installed and functional
- Enhanced deployment scripts with error handling

❌ **AUTHENTICATION ISSUES IDENTIFIED:**
- Connected App credentials in .env may be invalid or expired
- Connected App may lack required scopes
- Anypoint CLI v4 doesn't support `auth login` command (v3 syntax)

## Prerequisites Checklist

### 1. System Requirements
- [x] Maven 3.9.9 installed
- [x] Java 23 available (note: compatibility concerns with older Mule versions)
- [x] Anypoint CLI v4 1.6.14 installed
- [x] All Mule applications build successfully

### 2. Anypoint Platform Setup Required

#### Connected App Configuration
You need to create or update a Connected App in Anypoint Platform with these **exact** scopes:

**Required Scopes:**
```
✓ Runtime Manager: Read applications, Write applications
✓ CloudHub: Read applications, Write applications  
✓ Exchange: Read assets, Write assets
✓ Design Center: Read projects (optional)
✓ API Manager: Read API instances, Write API instances (optional)
```

**Steps to Create/Update Connected App:**
1. Log into Anypoint Platform
2. Go to **Access Management** → **Connected Apps**
3. Create new or edit existing Connected App
4. Set **Grant Type**: Client Credentials
5. Add all required scopes listed above
6. Save and copy Client ID and Client Secret

#### Environment Verification
1. Go to **Runtime Manager**
2. Verify your environment exists and you have deployment permissions
3. Check available vCore quota for CloudHub deployments

## Solution Strategies

### Strategy 1: Fix Connected App Authentication

Update your `.env` file with corrected credentials:

```bash
# ========================================
# ANYPOINT CLI CONFIGURATION - UPDATED
# ========================================
ANYPOINT_CLIENT_ID=your-new-connected-app-client-id
ANYPOINT_CLIENT_SECRET=your-new-connected-app-client-secret
ANYPOINT_ORG_ID=47562e5d-bf49-440a-a0f5-a9cea0a89aa9
ANYPOINT_ENV_NAME=Sandbox
ANYPOINT_BUSINESS_GROUP_ID=47562e5d-bf49-440a-a0f5-a9cea0a89aa9

# CloudHub Deployment Configuration - UPDATED FOR COMPATIBILITY
CLOUDHUB_REGION=us-east-1
CLOUDHUB_WORKER_TYPE=MICRO
CLOUDHUB_WORKERS=1
CLOUDHUB_MULE_VERSION=4.4.0  # Update to 4.6.0 for Java 17+ compatibility
```

### Strategy 2: Username/Password Authentication Alternative

Since Connected App authentication is failing, create an alternative authentication approach:

```batch
REM Alternative authentication using username/password
anypoint-cli-v4 conf username your-anypoint-username
anypoint-cli-v4 conf password your-anypoint-password
anypoint-cli-v4 conf organization 47562e5d-bf49-440a-a0f5-a9cea0a89aa9
anypoint-cli-v4 conf environment Sandbox
```

### Strategy 3: Manual Deployment Workflow

If automated authentication continues to fail, use this manual approach:

#### Step 1: Build All Applications
```bash
# Build Employee Onboarding MCP
cd employee-onboarding-mcp
mvn clean package -DskipTests
cd ..

# Build Asset Allocation MCP  
cd asset-allocation-mcp
mvn clean package -DskipTests
cd ..

# Build Notification MCP
cd notification-mcp
mvn clean package -DskipTests
cd ..

# Build Agent Fabric
cd agent-fabric
mvn clean package -DskipTests
cd ..
```

#### Step 2: Manual CloudHub Deployment via Web UI
1. Log into Anypoint Platform
2. Go to **Runtime Manager**
3. Click **Deploy application**
4. Upload each JAR file manually:
   - `employee-onboarding-mcp/target/employee-onboarding-mcp-server-1.0.1-mule-application.jar`
   - `asset-allocation-mcp/target/asset-allocation-mcp-server-1.0.0-mule-application.jar`
   - `notification-mcp/target/notification-mcp-server-1.0.0-mule-application.jar`
   - `agent-fabric/target/hr-onboarding-agent-fabric-1.0.0-mule-application.jar`

#### Step 3: Configure Runtime Properties
For each application, set these properties:

**Employee Onboarding MCP:**
```
http.port=8081
deployment.mode=cloud
db.mode=h2
api.key.header=X-API-Key
api.key.value=hr-mcp-secure-key-2024
```

**Asset Allocation MCP:**
```
http.port=8082
deployment.mode=cloud
db.mode=h2
api.key.header=X-API-Key
api.key.value=hr-mcp-secure-key-2024
```

**Notification MCP:**
```
http.port=8083
deployment.mode=cloud
db.mode=h2
api.key.header=X-API-Key
api.key.value=hr-mcp-secure-key-2024
```

**HR Onboarding Agent Fabric:**
```
http.port=8080
https.port=8443
deployment.mode=cloud
employee.mcp.url=https://employee-onboarding-mcp-{timestamp}.us-east-1.cloudhub.io
asset.mcp.url=https://asset-allocation-mcp-{timestamp}.us-east-1.cloudhub.io
notification.mcp.url=https://notification-mcp-{timestamp}.us-east-1.cloudhub.io
api.key.header=X-API-Key
api.key.value=hr-agent-secure-key-2024
agent.name=HR Onboarding Agent
agent.version=1.0.0
```

## Working Deployment Scripts

### Enhanced Script: `deploy-hybrid-enhanced.bat`
✅ **Already Created** - Includes multiple authentication fallback strategies

### Alternative Script: Username/Password Authentication

```batch
@echo off
REM Alternative deployment using username/password authentication
setlocal enabledelayedexpansion

echo ========================================
echo HR ONBOARDING AGENT - ALTERNATIVE DEPLOY
echo ========================================
echo Using username/password authentication...

REM Prompt for credentials
set /p ANYPOINT_USERNAME="Enter Anypoint Username: "
set /p ANYPOINT_PASSWORD="Enter Anypoint Password: "

REM Configure authentication
call anypoint-cli-v4 conf username %ANYPOINT_USERNAME%
call anypoint-cli-v4 conf password %ANYPOINT_PASSWORD%
call anypoint-cli-v4 conf organization 47562e5d-bf49-440a-a0f5-a9cea0a89aa9
call anypoint-cli-v4 conf environment Sandbox

REM Test authentication
echo Testing authentication...
call anypoint-cli-v4 account environment list
if errorlevel 1 (
    echo ERROR: Authentication failed
    goto :error
)

echo Authentication successful - proceeding with build and deployment...
REM Continue with build and deployment steps...
```

## Java Version Compatibility Issue

**⚠️ IMPORTANT:** You're running Java 23, but the current Mule runtime version (4.4.0) may have compatibility issues.

**Recommended Actions:**
1. **Update Mule Runtime:** Change `CLOUDHUB_MULE_VERSION=4.6.0` in .env file
2. **Or Install Java 11:** Download and install Java 11 for better compatibility
3. **Set JAVA_HOME:** Ensure Maven uses compatible Java version

```bash
# Check current Java version
java --version

# Check Maven's Java version
mvn --version
```

## Verification Steps

Once deployment is successful, test these endpoints:

```bash
# Health checks
curl https://hr-onboarding-agent-{timestamp}.us-east-1.cloudhub.io/agent/health
curl https://employee-onboarding-mcp-{timestamp}.us-east-1.cloudhub.io/mcp/health
curl https://asset-allocation-mcp-{timestamp}.us-east-1.cloudhub.io/mcp/health
curl https://notification-mcp-{timestamp}.us-east-1.cloudhub.io/mcp/health

# Sample onboarding request
curl -X POST https://hr-onboarding-agent-{timestamp}.us-east-1.cloudhub.io/agent/onboard \
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

## Next Steps

1. **Fix Connected App:** Update credentials in .env file with working Connected App
2. **Update Runtime Version:** Change to Mule 4.6.0 for Java compatibility
3. **Test Authentication:** Run authentication test commands
4. **Deploy Applications:** Use enhanced script or manual deployment
5. **Verify Endpoints:** Test all health checks and API endpoints
6. **Monitor Applications:** Check CloudHub logs and performance metrics

## Troubleshooting

### Authentication Issues
- Verify Connected App scopes and credentials
- Try username/password authentication
- Check organization and environment IDs
- Ensure user has deployment permissions

### Build Issues  
- Java 23 compatibility with older Mule versions
- Update to Mule 4.6.0 runtime
- Check Maven dependencies and repositories

### Deployment Issues
- Verify CloudHub vCore quota
- Check application naming conflicts
- Review runtime properties configuration
- Monitor CloudHub region availability

## Success Criteria

✅ **Deployment Successful When:**
- All 4 applications deployed to CloudHub
- Health endpoints return 200 OK
- Agent Fabric can communicate with MCP servers
- Sample onboarding request completes successfully
- Applications appear in Runtime Manager console

---

**Current Status:** Maven builds are working ✅, Authentication needs to be resolved ❌

**Next Action Required:** Update Connected App credentials or use alternative authentication method.
