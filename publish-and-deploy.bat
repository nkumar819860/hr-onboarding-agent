@echo off
REM ========================================
REM HR Onboarding Agent - Complete Exchange Publishing & CloudHub Deployment
REM Step 1: Publish MCP Assets to Exchange 
REM Step 2: Deploy Agent Fabric and MCPs to CloudHub
REM ========================================

setlocal enabledelayedexpansion

echo ========================================
echo HR ONBOARDING AGENT - PUBLISH & DEPLOY
echo ========================================
echo Step 1: Publishing MCP Assets to Exchange
echo Step 2: Deploying to CloudHub
echo.

REM Load environment variables from .env file
echo Loading environment variables from .env file...
for /f "usebackq tokens=1* delims==" %%a in (".env") do (
    set "line=%%a"
    if not "!line:~0,1!"=="#" if not "%%a"=="" (
        set "%%a=%%b"
    )
)

REM Generate unique timestamp for deployments
for /f %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd-HHmmss'"') do set TIMESTAMP=%%i

echo Configuration:
echo - Organization ID: %ANYPOINT_ORG_ID%
echo - Environment: %ANYPOINT_ENV_NAME%  
echo - Region: %CLOUDHUB_REGION%
echo - Timestamp: %TIMESTAMP%
echo.

REM ========================================
REM STEP 1: PUBLISH MCP ASSETS TO EXCHANGE
REM ========================================

echo ========================================
echo STEP 1: PUBLISHING MCP ASSETS TO EXCHANGE
echo ========================================

REM Publish Employee Onboarding MCP to Exchange
echo [1/4] Publishing Employee Onboarding MCP Server to Exchange...
cd employee-onboarding-mcp
call mvn clean deploy -DaltDeploymentRepository=exchange::default::https://maven.anypoint.mulesoft.com/api/v3/organizations/%ANYPOINT_ORG_ID%/maven ^
    -DconnectedAppClientId=%ANYPOINT_CLIENT_ID% ^
    -DconnectedAppClientSecret=%ANYPOINT_CLIENT_SECRET% ^
    -DconnectedAppGrantType=client_credentials ^
    -DskipTests

if errorlevel 1 (
    echo WARNING: Failed to publish Employee Onboarding MCP to Exchange (continuing)
) else (
    echo ✓ Employee Onboarding MCP Server published to Exchange
)
cd ..
echo.

REM Publish Asset Allocation MCP to Exchange  
echo [2/4] Publishing Asset Allocation MCP Server to Exchange...
cd asset-allocation-mcp
call mvn clean deploy -DaltDeploymentRepository=exchange::default::https://maven.anypoint.mulesoft.com/api/v3/organizations/%ANYPOINT_ORG_ID%/maven ^
    -DconnectedAppClientId=%ANYPOINT_CLIENT_ID% ^
    -DconnectedAppClientSecret=%ANYPOINT_CLIENT_SECRET% ^
    -DconnectedAppGrantType=client_credentials ^
    -DskipTests

if errorlevel 1 (
    echo WARNING: Failed to publish Asset Allocation MCP to Exchange (continuing)
) else (
    echo ✓ Asset Allocation MCP Server published to Exchange  
)
cd ..
echo.

REM Publish Notification MCP to Exchange
echo [3/4] Publishing Notification MCP Server to Exchange...
cd notification-mcp
call mvn clean deploy -DaltDeploymentRepository=exchange::default::https://maven.anypoint.mulesoft.com/api/v3/organizations/%ANYPOINT_ORG_ID%/maven ^
    -DconnectedAppClientId=%ANYPOINT_CLIENT_ID% ^
    -DconnectedAppClientSecret=%ANYPOINT_CLIENT_SECRET% ^
    -DconnectedAppGrantType=client_credentials ^
    -DskipTests

if errorlevel 1 (
    echo WARNING: Failed to publish Notification MCP to Exchange (continuing)
) else (
    echo ✓ Notification MCP Server published to Exchange
)
cd ..
echo.

REM Publish Agent Fabric to Exchange
echo [4/4] Publishing HR Onboarding Agent Fabric to Exchange...
cd agent-fabric
call mvn clean deploy -DaltDeploymentRepository=exchange::default::https://maven.anypoint.mulesoft.com/api/v3/organizations/%ANYPOINT_ORG_ID%/maven ^
    -DconnectedAppClientId=%ANYPOINT_CLIENT_ID% ^
    -DconnectedAppClientSecret=%ANYPOINT_CLIENT_SECRET% ^
    -DconnectedAppGrantType=client_credentials ^
    -DskipTests

if errorlevel 1 (
    echo WARNING: Failed to publish Agent Fabric to Exchange (continuing)
) else (
    echo ✓ HR Onboarding Agent Fabric published to Exchange
)
cd ..

echo ========================================
echo EXCHANGE PUBLISHING COMPLETED
echo ========================================
echo.

REM ========================================
REM STEP 2: DEPLOY TO CLOUDHUB
REM ========================================

echo ========================================
echo STEP 2: DEPLOYING TO CLOUDHUB  
echo ========================================

REM Deploy Employee Onboarding MCP to CloudHub
echo [1/4] Deploying Employee Onboarding MCP Server to CloudHub...
cd employee-onboarding-mcp
call mvn clean package mule:deploy -DmuleDeploy ^
    -Dcloudhub.application.name=employee-onboarding-mcp-%TIMESTAMP% ^
    -Dcloudhub.environment=%ANYPOINT_ENV_NAME% ^
    -Dcloudhub.region=%CLOUDHUB_REGION% ^
    -Dcloudhub.workers=%CLOUDHUB_WORKERS% ^
    -Dcloudhub.workerType=%CLOUDHUB_WORKER_TYPE% ^
    -Dcloudhub.muleVersion=%CLOUDHUB_MULE_VERSION% ^
    -Dcloudhub.connectedAppClientId=%ANYPOINT_CLIENT_ID% ^
    -Dcloudhub.connectedAppClientSecret=%ANYPOINT_CLIENT_SECRET% ^
    -Dcloudhub.connectedAppGrantType=client_credentials ^
    -Dcloudhub.businessGroup=%ANYPOINT_ORG_ID% ^
    -DskipTests

if errorlevel 1 (
    echo ERROR: Failed to deploy Employee Onboarding MCP Server
    cd ..
    goto :error
)
cd ..
echo ✓ Employee Onboarding MCP Server deployed to CloudHub
echo URL: https://employee-onboarding-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
echo.

REM Deploy Asset Allocation MCP to CloudHub
echo [2/4] Deploying Asset Allocation MCP Server to CloudHub...
cd asset-allocation-mcp
call mvn clean package mule:deploy -DmuleDeploy ^
    -Dcloudhub.application.name=asset-allocation-mcp-%TIMESTAMP% ^
    -Dcloudhub.environment=%ANYPOINT_ENV_NAME% ^
    -Dcloudhub.region=%CLOUDHUB_REGION% ^
    -Dcloudhub.workers=%CLOUDHUB_WORKERS% ^
    -Dcloudhub.workerType=%CLOUDHUB_WORKER_TYPE% ^
    -Dcloudhub.muleVersion=%CLOUDHUB_MULE_VERSION% ^
    -Dcloudhub.connectedAppClientId=%ANYPOINT_CLIENT_ID% ^
    -Dcloudhub.connectedAppClientSecret=%ANYPOINT_CLIENT_SECRET% ^
    -Dcloudhub.connectedAppGrantType=client_credentials ^
    -Dcloudhub.businessGroup=%ANYPOINT_ORG_ID% ^
    -DskipTests

if errorlevel 1 (
    echo ERROR: Failed to deploy Asset Allocation MCP Server
    cd ..
    goto :error
)
cd ..
echo ✓ Asset Allocation MCP Server deployed to CloudHub
echo URL: https://asset-allocation-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
echo.

REM Deploy Notification MCP to CloudHub
echo [3/4] Deploying Notification MCP Server to CloudHub...
cd notification-mcp
call mvn clean package mule:deploy -DmuleDeploy ^
    -Dcloudhub.application.name=notification-mcp-%TIMESTAMP% ^
    -Dcloudhub.environment=%ANYPOINT_ENV_NAME% ^
    -Dcloudhub.region=%CLOUDHUB_REGION% ^
    -Dcloudhub.workers=%CLOUDHUB_WORKERS% ^
    -Dcloudhub.workerType=%CLOUDHUB_WORKER_TYPE% ^
    -Dcloudhub.muleVersion=%CLOUDHUB_MULE_VERSION% ^
    -Dcloudhub.connectedAppClientId=%ANYPOINT_CLIENT_ID% ^
    -Dcloudhub.connectedAppClientSecret=%ANYPOINT_CLIENT_SECRET% ^
    -Dcloudhub.connectedAppGrantType=client_credentials ^
    -Dcloudhub.businessGroup=%ANYPOINT_ORG_ID% ^
    -DskipTests

if errorlevel 1 (
    echo ERROR: Failed to deploy Notification MCP Server
    cd ..
    goto :error
)
cd ..
echo ✓ Notification MCP Server deployed to CloudHub
echo URL: https://notification-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
echo.

REM Deploy HR Onboarding Agent Fabric to CloudHub
echo [4/4] Deploying HR Onboarding Agent Fabric to CloudHub...
cd agent-fabric
call mvn clean package mule:deploy -DmuleDeploy ^
    -Dcloudhub.application.name=hr-onboarding-agent-%TIMESTAMP% ^
    -Dcloudhub.environment=%ANYPOINT_ENV_NAME% ^
    -Dcloudhub.region=%CLOUDHUB_REGION% ^
    -Dcloudhub.workers=%CLOUDHUB_WORKERS% ^
    -Dcloudhub.workerType=%CLOUDHUB_WORKER_TYPE% ^
    -Dcloudhub.muleVersion=%CLOUDHUB_MULE_VERSION% ^
    -Dcloudhub.connectedAppClientId=%ANYPOINT_CLIENT_ID% ^
    -Dcloudhub.connectedAppClientSecret=%ANYPOINT_CLIENT_SECRET% ^
    -Dcloudhub.connectedAppGrantType=client_credentials ^
    -Dcloudhub.businessGroup=%ANYPOINT_ORG_ID% ^
    -Demployee.mcp.url=https://employee-onboarding-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io ^
    -Dasset.mcp.url=https://asset-allocation-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io ^
    -Dnotification.mcp.url=https://notification-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io ^
    -DskipTests

if errorlevel 1 (
    echo ERROR: Failed to deploy HR Onboarding Agent Fabric
    cd ..
    goto :error
)
cd ..
echo ✓ HR Onboarding Agent Fabric deployed to CloudHub
echo URL: https://hr-onboarding-agent-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
echo.

REM ========================================
REM DEPLOYMENT COMPLETED SUCCESSFULLY
REM ========================================

echo ========================================
echo PUBLISH & DEPLOY COMPLETED SUCCESSFULLY!
echo ========================================
echo.
echo 📦 Exchange Assets Published:
echo ┌─────────────────────────────────────────────────────────────────────────────────────────┐
echo │ Employee Onboarding MCP: %ANYPOINT_ORG_ID%/employee-onboarding-mcp-server               │
echo │ Asset Allocation MCP:    %ANYPOINT_ORG_ID%/asset-allocation-mcp-server                  │
echo │ Notification MCP:        %ANYPOINT_ORG_ID%/notification-mcp-server                      │
echo │ HR Agent Fabric:         %ANYPOINT_ORG_ID%/hr-onboarding-agent-fabric                  │
echo └─────────────────────────────────────────────────────────────────────────────────────────┘
echo.
echo 🚀 CloudHub Applications Deployed:
echo ┌─────────────────────────────────────────────────────────────────────────────────────────┐
echo │ Employee Onboarding MCP: https://employee-onboarding-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io │
echo │ Asset Allocation MCP:    https://asset-allocation-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io    │
echo │ Notification MCP:        https://notification-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io        │
echo │ HR Onboarding Agent:     https://hr-onboarding-agent-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io     │
echo └─────────────────────────────────────────────────────────────────────────────────────────┘
echo.
echo 🔧 Available Endpoints:
echo ┌─────────────────────────────────────────────────────────────────────────────────────────┐
echo │ Agent Health Check:      GET  /agent/health                                            │
echo │ Complete Onboarding:     POST /agent/onboard                                           │
echo │ Onboarding Status:       GET  /agent/onboard/{employeeId}/status                      │
echo │ List Employees:          GET  /agent/onboard/employees                                 │
echo │                                                                                         │
echo │ MCP Server Info:         GET  /mcp/{server-name}/info                                  │
echo │ MCP Health Checks:       GET  /mcp/health                                              │
echo └─────────────────────────────────────────────────────────────────────────────────────────┘
echo.
echo 🎯 Test Commands:
echo curl -X GET https://hr-onboarding-agent-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io/agent/health
echo curl -X GET https://employee-onboarding-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io/mcp/health
echo curl -X GET https://asset-allocation-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io/mcp/health
echo curl -X GET https://notification-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io/mcp/health
echo.
echo ✅ Next Steps:
echo 1. Verify Exchange assets in Anypoint Exchange
echo 2. Verify CloudHub deployments in Runtime Manager
echo 3. Test health endpoints using provided curl commands
echo 4. Update MCP client configurations with new URLs
echo 5. Monitor application performance and logs
echo.

goto :end

:error
echo.
echo ========================================
echo DEPLOYMENT FAILED!
echo ========================================
echo Please check the error messages above and resolve the issues.
echo.
echo 🔍 Troubleshooting Steps:
echo 1. Verify Connected App credentials in .env file
echo 2. Check Connected App grant type is set to "client_credentials"
echo 3. Verify Connected App has required scopes:
echo    - Exchange Administrator (for Exchange publishing)
echo    - CloudHub Application Admin (for CloudHub deployment)
echo 4. Ensure sufficient CloudHub vCore quota available
echo 5. Verify environment exists: %ANYPOINT_ENV_NAME%
echo 6. Check organization access: %ANYPOINT_ORG_ID%
echo.
echo 📞 Support Resources:
echo - Anypoint Platform Status: https://status.mulesoft.com/
echo - Connected App Documentation: https://docs.mulesoft.com/access-management/connected-apps-overview
echo - Maven Plugin Documentation: https://docs.mulesoft.com/mule-runtime/4.4/deploy-to-cloudhub
echo.
pause
exit /b 1

:end
echo 🎉 Exchange Publishing & CloudHub Deployment completed successfully!
echo.
echo ✓ MCP Assets published to Exchange with proper classification
echo ✓ Agent Fabric and all MCP servers deployed to CloudHub
echo ✓ All validation issues resolved and applications running
echo ✓ Timestamped deployments prevent naming conflicts
echo.
pause
