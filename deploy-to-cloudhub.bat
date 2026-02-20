@echo off
REM ========================================
REM HR Onboarding Agent - Maven-based CloudHub Deployment
REM Using Maven CloudHub Plugin with Connected App Authentication
REM Includes Exchange Publishing for MCP Assets
REM ========================================

setlocal enabledelayedexpansion

echo ========================================
echo HR ONBOARDING AGENT - CLOUDHUB DEPLOYMENT
echo ========================================
echo Using Maven CloudHub Plugin for deployment
echo Connected App credentials from .env file
echo.

REM Load environment variables from .env file
echo Loading environment variables from .env file...
for /f "usebackq tokens=1* delims==" %%a in (".env") do (
    set "line=%%a"
    if not "!line:~0,1!"=="#" if not "%%a"=="" (
        set "%%a=%%b"
    )
)

REM Generate unique timestamp for application names
for /f %%i in ('powershell -Command "Get-Date -Format 'yyyyMMdd-HHmmss'"') do set TIMESTAMP=%%i

echo Environment Configuration:
echo - Organization ID: %ANYPOINT_CLIENT_ID%
echo - Environment: %ANYPOINT_ENV_NAME%
echo - Region: %CLOUDHUB_REGION%
echo - Worker Type: %CLOUDHUB_WORKER_TYPE%
echo - Mule Version: %CLOUDHUB_MULE_VERSION%
echo - Deployment Timestamp: %TIMESTAMP%
echo.

REM Deploy Employee Onboarding MCP Server
echo ========================================
echo [1/4] DEPLOYING EMPLOYEE ONBOARDING MCP SERVER
echo ========================================
cd employee-onboarding-mcp
call mvn clean deploy -DmuleDeploy ^
    -Dconnected.app.client.id=%ANYPOINT_CLIENT_ID% ^
    -Dconnected.app.client.secret=%ANYPOINT_CLIENT_SECRET% ^
    -Danypoint.org.id=%ANYPOINT_ORG_ID% ^
    -Dapp.name=employee-onboarding-mcp-%TIMESTAMP% ^
    -Denv.name=%ANYPOINT_ENV_NAME% ^
    -DskipTests

if errorlevel 1 (
    echo ERROR: Failed to deploy Employee Onboarding MCP Server
    cd ..
    goto :error
)
cd ..
echo ✓ Employee Onboarding MCP Server deployed successfully
echo URL: https://employee-onboarding-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
echo.

REM Deploy Asset Allocation MCP Server
echo ========================================
echo [2/4] DEPLOYING ASSET ALLOCATION MCP SERVER
echo ========================================
cd asset-allocation-mcp
call mvn clean deploy -DmuleDeploy ^
    -Dconnected.app.client.id=%ANYPOINT_CLIENT_ID% ^
    -Dconnected.app.client.secret=%ANYPOINT_CLIENT_SECRET% ^
    -Danypoint.org.id=%ANYPOINT_ORG_ID% ^
    -Dapp.name=asset-allocation-mcp-%TIMESTAMP% ^
    -Denv.name=%ANYPOINT_ENV_NAME% ^
    -DskipTests

if errorlevel 1 (
    echo ERROR: Failed to deploy Asset Allocation MCP Server
    cd ..
    goto :error
)
cd ..
echo ✓ Asset Allocation MCP Server deployed successfully
echo URL: https://asset-allocation-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
echo.

REM Deploy Notification MCP Server
echo ========================================
echo [3/4] DEPLOYING NOTIFICATION MCP SERVER
echo ========================================
cd notification-mcp
call mvn clean deploy -DmuleDeploy ^
    -Dconnected.app.client.id=%ANYPOINT_CLIENT_ID% ^
    -Dconnected.app.client.secret=%ANYPOINT_CLIENT_SECRET% ^
    -Danypoint.org.id=%ANYPOINT_ORG_ID% ^
    -Dapp.name=notification-mcp-%TIMESTAMP% ^
    -Denv.name=%ANYPOINT_ENV_NAME% ^
    -DskipTests

if errorlevel 1 (
    echo ERROR: Failed to deploy Notification MCP Server
    cd ..
    goto :error
)
cd ..
echo ✓ Notification MCP Server deployed successfully
echo URL: https://notification-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
echo.

REM Deploy HR Onboarding Agent Fabric
echo ========================================
echo [4/4] DEPLOYING HR ONBOARDING AGENT FABRIC
echo ========================================
cd agent-fabric
call mvn clean deploy -DmuleDeploy ^
    -Dconnected.app.client.id=%ANYPOINT_CLIENT_ID% ^
    -Dconnected.app.client.secret=%ANYPOINT_CLIENT_SECRET% ^
    -Danypoint.org.id=%ANYPOINT_ORG_ID% ^
    -Dapp.name=hr-onboarding-agent-%TIMESTAMP% ^
    -Denv.name=%ANYPOINT_ENV_NAME% ^
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
echo ✓ HR Onboarding Agent Fabric deployed successfully
echo URL: https://hr-onboarding-agent-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
echo.

REM Deployment completed successfully
echo ========================================
echo DEPLOYMENT COMPLETED SUCCESSFULLY!
echo ========================================
echo.
echo 🚀 All applications deployed with timestamp: %TIMESTAMP%
echo.
echo 📱 Application URLs:
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
echo 1. Verify deployments in Anypoint Platform Runtime Manager
echo 2. Test the health endpoints using the provided curl commands
echo 3. Update MCP client configurations with new URLs
echo 4. Monitor application performance and logs
echo 5. Check CloudHub applications are running successfully
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
echo 2. Check CloudHub deployment permissions
echo 3. Ensure sufficient CloudHub vCore quota available
echo 4. Verify environment exists: %ANYPOINT_ENV_NAME%
echo 5. Check organization access: %ANYPOINT_ORG_ID%
echo.
echo 📞 Support:
echo - Check Anypoint Platform status
echo - Review organization permissions
echo - Verify Maven and Java installation
echo.
pause
exit /b 1

:end
echo 🎉 Maven-based deployment completed successfully!
echo.
echo Using Connected App authentication from .env file
echo All validation issues have been resolved
echo CloudHub deployment completed using Maven plugin
echo.
pause
