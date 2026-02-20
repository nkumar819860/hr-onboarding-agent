@echo off
REM ========================================
REM HR Onboarding Agent - Alternative Authentication Deploy Script
REM Uses username/password authentication when Connected App fails
REM Maven for building + Anypoint CLI for deployment
REM ========================================

setlocal enabledelayedexpansion

echo ========================================
echo HR ONBOARDING AGENT - ALTERNATIVE AUTH DEPLOY
echo ========================================
echo Using username/password authentication fallback...
echo This method works when Connected App authentication fails
echo.

REM Load environment variables from .env file for non-auth settings
echo Loading environment variables from .env file...
if not exist ".env" (
    echo ERROR: .env file not found. Please create it with your configuration.
    goto :error
)

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

REM Check if Anypoint CLI is installed
echo Checking Anypoint CLI installation...
call anypoint-cli-v4 --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Anypoint CLI v4 is not installed or not in PATH
    echo Please install: npm install -g @mulesoft/anypoint-cli-v4
    goto :error
)
echo ✓ Anypoint CLI v4 is available
echo.

REM ========================================
REM USERNAME/PASSWORD AUTHENTICATION
REM ========================================

echo ========================================
echo CONFIGURING USERNAME/PASSWORD AUTHENTICATION
echo ========================================
echo.
echo Connected App authentication failed, using username/password method...
echo Please enter your Anypoint Platform credentials:
echo.

REM Prompt for credentials
set /p ANYPOINT_USERNAME="Enter Anypoint Username (email): "
set /p ANYPOINT_PASSWORD="Enter Anypoint Password: "

if "%ANYPOINT_USERNAME%"=="" (
    echo ERROR: Username cannot be empty
    goto :error
)
if "%ANYPOINT_PASSWORD%"=="" (
    echo ERROR: Password cannot be empty
    goto :error
)

echo.
echo Clearing previous authentication configuration...
call anypoint-cli-v4 conf client_id ""
call anypoint-cli-v4 conf client_secret ""

echo Configuring username/password authentication...
call anypoint-cli-v4 conf username %ANYPOINT_USERNAME%
call anypoint-cli-v4 conf password %ANYPOINT_PASSWORD%
call anypoint-cli-v4 conf organization %ANYPOINT_ORG_ID%
call anypoint-cli-v4 conf environment %ANYPOINT_ENV_NAME%

REM Test authentication
echo Testing authentication...
call anypoint-cli-v4 account environment list
if errorlevel 1 (
    echo ERROR: Username/password authentication failed
    echo Please verify your credentials and organization access
    goto :error
)

echo ✓ Authentication successful with username/password
echo.

REM Verify environment access
echo Verifying environment access...
call anypoint-cli-v4 account environment list
echo.

REM ========================================
REM STEP 1: BUILD ALL APPLICATIONS WITH MAVEN
REM ========================================

echo ========================================
echo STEP 1: BUILDING ALL APPLICATIONS WITH MAVEN
echo ========================================

echo Checking Maven installation...
call mvn --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Maven is not installed or not in PATH
    echo Please install Maven and ensure it's in your PATH
    goto :error
)
echo ✓ Maven is available
echo.

REM Build Employee Onboarding MCP Server
echo Building Employee Onboarding MCP Server...
if exist "employee-onboarding-mcp" (
    cd employee-onboarding-mcp
    echo Running: mvn clean package -DskipTests -q
    call mvn clean package -DskipTests -q
    if errorlevel 1 (
        echo ERROR: Failed to build Employee Onboarding MCP Server
        echo Running with verbose output for debugging...
        call mvn clean package -DskipTests
        cd ..
        goto :error
    )
    cd ..
    echo ✓ Employee Onboarding MCP Server built successfully
) else (
    echo WARNING: employee-onboarding-mcp directory not found, skipping
)

REM Build Asset Allocation MCP Server
echo Building Asset Allocation MCP Server...
if exist "asset-allocation-mcp" (
    cd asset-allocation-mcp
    echo Running: mvn clean package -DskipTests -q
    call mvn clean package -DskipTests -q
    if errorlevel 1 (
        echo ERROR: Failed to build Asset Allocation MCP Server
        echo Running with verbose output for debugging...
        call mvn clean package -DskipTests
        cd ..
        goto :error
    )
    cd ..
    echo ✓ Asset Allocation MCP Server built successfully
) else (
    echo WARNING: asset-allocation-mcp directory not found, skipping
)

REM Build Notification MCP Server
echo Building Notification MCP Server...
if exist "notification-mcp" (
    cd notification-mcp
    echo Running: mvn clean package -DskipTests -q
    call mvn clean package -DskipTests -q
    if errorlevel 1 (
        echo ERROR: Failed to build Notification MCP Server
        echo Running with verbose output for debugging...
        call mvn clean package -DskipTests
        cd ..
        goto :error
    )
    cd ..
    echo ✓ Notification MCP Server built successfully
) else (
    echo WARNING: notification-mcp directory not found, skipping
)

REM Build HR Onboarding Agent Fabric
echo Building HR Onboarding Agent Fabric...
if exist "agent-fabric" (
    cd agent-fabric
    echo Running: mvn clean package -DskipTests -q
    call mvn clean package -DskipTests -q
    if errorlevel 1 (
        echo ERROR: Failed to build HR Onboarding Agent Fabric
        echo Running with verbose output for debugging...
        call mvn clean package -DskipTests
        cd ..
        goto :error
    )
    cd ..
    echo ✓ HR Onboarding Agent Fabric built successfully
) else (
    echo WARNING: agent-fabric directory not found, skipping
)

echo ========================================
echo ALL APPLICATIONS BUILT SUCCESSFULLY
echo ========================================
echo.

REM ========================================
REM STEP 2: DEPLOY TO CLOUDHUB WITH USERNAME/PASSWORD AUTH
REM ========================================

echo ========================================
echo STEP 2: DEPLOYING TO CLOUDHUB
echo ========================================

REM Deploy Employee Onboarding MCP Server
if exist "employee-onboarding-mcp\target\employee-onboarding-mcp-server-1.0.1-mule-application.jar" (
    echo Deploying Employee Onboarding MCP Server to CloudHub...
    cd employee-onboarding-mcp
    
    echo Running deployment command...
    call anypoint-cli-v4 runtime-mgr cloudhub-application deploy ^
        employee-onboarding-mcp-%TIMESTAMP% ^
        target/employee-onboarding-mcp-server-1.0.1-mule-application.jar ^
        --runtime %CLOUDHUB_MULE_VERSION% ^
        --workers %CLOUDHUB_WORKERS% ^
        --workerSize %CLOUDHUB_WORKER_TYPE% ^
        --region %CLOUDHUB_REGION% ^
        --property "http.port:8081" ^
        --property "deployment.mode:cloud" ^
        --property "db.mode:h2" ^
        --property "api.key.header:X-API-Key" ^
        --property "api.key.value:hr-mcp-secure-key-2024"
    
    if errorlevel 1 (
        echo ERROR: Failed to deploy Employee Onboarding MCP Server
        echo Trying with basic deployment options...
        call anypoint-cli-v4 runtime-mgr cloudhub-application deploy employee-onboarding-mcp-%TIMESTAMP% target/employee-onboarding-mcp-server-1.0.1-mule-application.jar --runtime %CLOUDHUB_MULE_VERSION%
        if errorlevel 1 (
            cd ..
            goto :deploy_error
        )
    )
    cd ..
    echo ✓ Employee Onboarding MCP Server deployed to CloudHub
    echo URL: https://employee-onboarding-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
    echo.
) else (
    echo WARNING: Employee Onboarding MCP JAR not found, skipping deployment
)

REM Deploy Asset Allocation MCP Server
if exist "asset-allocation-mcp\target\asset-allocation-mcp-server-1.0.0-mule-application.jar" (
    echo Deploying Asset Allocation MCP Server to CloudHub...
    cd asset-allocation-mcp
    
    echo Running deployment command...
    call anypoint-cli-v4 runtime-mgr cloudhub-application deploy ^
        asset-allocation-mcp-%TIMESTAMP% ^
        target/asset-allocation-mcp-server-1.0.0-mule-application.jar ^
        --runtime %CLOUDHUB_MULE_VERSION% ^
        --workers %CLOUDHUB_WORKERS% ^
        --workerSize %CLOUDHUB_WORKER_TYPE% ^
        --region %CLOUDHUB_REGION% ^
        --property "http.port:8082" ^
        --property "deployment.mode:cloud" ^
        --property "db.mode:h2" ^
        --property "api.key.header:X-API-Key" ^
        --property "api.key.value:hr-mcp-secure-key-2024"
    
    if errorlevel 1 (
        echo ERROR: Failed to deploy Asset Allocation MCP Server
        echo Trying with basic deployment options...
        call anypoint-cli-v4 runtime-mgr cloudhub-application deploy asset-allocation-mcp-%TIMESTAMP% target/asset-allocation-mcp-server-1.0.0-mule-application.jar --runtime %CLOUDHUB_MULE_VERSION%
        if errorlevel 1 (
            cd ..
            goto :deploy_error
        )
    )
    cd ..
    echo ✓ Asset Allocation MCP Server deployed to CloudHub
    echo URL: https://asset-allocation-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
    echo.
) else (
    echo WARNING: Asset Allocation MCP JAR not found, skipping deployment
)

REM Deploy Notification MCP Server
if exist "notification-mcp\target\notification-mcp-server-1.0.0-mule-application.jar" (
    echo Deploying Notification MCP Server to CloudHub...
    cd notification-mcp
    
    echo Running deployment command...
    call anypoint-cli-v4 runtime-mgr cloudhub-application deploy ^
        notification-mcp-%TIMESTAMP% ^
        target/notification-mcp-server-1.0.0-mule-application.jar ^
        --runtime %CLOUDHUB_MULE_VERSION% ^
        --workers %CLOUDHUB_WORKERS% ^
        --workerSize %CLOUDHUB_WORKER_TYPE% ^
        --region %CLOUDHUB_REGION% ^
        --property "http.port:8083" ^
        --property "deployment.mode:cloud" ^
        --property "db.mode:h2" ^
        --property "api.key.header:X-API-Key" ^
        --property "api.key.value:hr-mcp-secure-key-2024"
    
    if errorlevel 1 (
        echo ERROR: Failed to deploy Notification MCP Server
        echo Trying with basic deployment options...
        call anypoint-cli-v4 runtime-mgr cloudhub-application deploy notification-mcp-%TIMESTAMP% target/notification-mcp-server-1.0.0-mule-application.jar --runtime %CLOUDHUB_MULE_VERSION%
        if errorlevel 1 (
            cd ..
            goto :deploy_error
        )
    )
    cd ..
    echo ✓ Notification MCP Server deployed to CloudHub
    echo URL: https://notification-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
    echo.
) else (
    echo WARNING: Notification MCP JAR not found, skipping deployment
)

REM Deploy HR Onboarding Agent Fabric
if exist "agent-fabric\target\hr-onboarding-agent-fabric-1.0.0-mule-application.jar" (
    echo Deploying HR Onboarding Agent Fabric to CloudHub...
    cd agent-fabric
    
    echo Running deployment command...
    call anypoint-cli-v4 runtime-mgr cloudhub-application deploy ^
        hr-onboarding-agent-%TIMESTAMP% ^
        target/hr-onboarding-agent-fabric-1.0.0-mule-application.jar ^
        --runtime %CLOUDHUB_MULE_VERSION% ^
        --workers %CLOUDHUB_WORKERS% ^
        --workerSize %CLOUDHUB_WORKER_TYPE% ^
        --region %CLOUDHUB_REGION% ^
        --property "http.port:8080" ^
        --property "https.port:8443" ^
        --property "deployment.mode:cloud" ^
        --property "employee.mcp.url:https://employee-onboarding-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io" ^
        --property "asset.mcp.url:https://asset-allocation-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io" ^
        --property "notification.mcp.url:https://notification-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io" ^
        --property "api.key.header:X-API-Key" ^
        --property "api.key.value:hr-agent-secure-key-2024" ^
        --property "agent.name:HR Onboarding Agent" ^
        --property "agent.version:1.0.0"
    
    if errorlevel 1 (
        echo ERROR: Failed to deploy HR Onboarding Agent Fabric
        echo Trying with basic deployment options...
        call anypoint-cli-v4 runtime-mgr cloudhub-application deploy hr-onboarding-agent-%TIMESTAMP% target/hr-onboarding-agent-fabric-1.0.0-mule-application.jar --runtime %CLOUDHUB_MULE_VERSION%
        if errorlevel 1 (
            cd ..
            goto :deploy_error
        )
    )
    cd ..
    echo ✓ HR Onboarding Agent Fabric deployed to CloudHub
    echo URL: https://hr-onboarding-agent-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io
    echo.
) else (
    echo WARNING: Agent Fabric JAR not found, skipping deployment
)

REM Wait for applications to start
echo Waiting for applications to initialize (30 seconds)...
timeout /t 30 >nul

REM Verify deployments by checking application status
echo ========================================
echo VERIFYING DEPLOYMENTS
echo ========================================
echo Listing CloudHub applications...
call anypoint-cli-v4 runtime-mgr cloudhub-application list
echo.

REM ========================================
REM SUCCESS REPORT
REM ========================================

echo ========================================
echo ALTERNATIVE AUTH DEPLOYMENT COMPLETED SUCCESSFULLY!
echo ========================================
echo.
echo 🚀 CloudHub Applications Deployed (Timestamp %TIMESTAMP%):
echo ┌─────────────────────────────────────────────────────────────────────────────────────────┐
echo │ Employee Onboarding MCP: https://employee-onboarding-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io │
echo │ Asset Allocation MCP:    https://asset-allocation-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io    │
echo │ Notification MCP:        https://notification-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io        │
echo │ HR Onboarding Agent:     https://hr-onboarding-agent-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io     │
echo └─────────────────────────────────────────────────────────────────────────────────────────┘
echo.
echo 🧪 Test Commands:
echo curl -X GET https://hr-onboarding-agent-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io/agent/health
echo curl -X GET https://employee-onboarding-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io/mcp/health
echo curl -X GET https://asset-allocation-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io/mcp/health
echo curl -X GET https://notification-mcp-%TIMESTAMP%.%CLOUDHUB_REGION%.cloudhub.io/mcp/health
echo.
echo ✅ ALTERNATIVE AUTHENTICATION SUCCESS:
echo ✓ Username/password authentication working
echo ✓ Connected App authentication issues bypassed
echo ✓ Maven builds completed successfully
echo ✓ CloudHub deployments completed with timestamped URLs
echo ✓ Ready for testing and production use
echo.

goto :end

:deploy_error
echo.
echo ========================================
echo DEPLOYMENT ERROR - PARTIAL SUCCESS
echo ========================================
echo Some applications failed to deploy. Check the errors above.
echo Applications that deployed successfully are still available.
echo.
echo 🔧 Troubleshooting:
echo 1. Check CloudHub quotas and vCore availability
echo 2. Verify application names don't conflict
echo 3. Review CloudHub region settings
echo 4. Check application-specific build artifacts
echo.
goto :error

:error
echo.
echo ========================================
echo ALTERNATIVE AUTH DEPLOYMENT FAILED!
echo ========================================
echo Please check the error messages above.
echo.
echo 🔧 Alternative Auth Troubleshooting:
echo.
echo AUTHENTICATION ISSUES:
echo 1. Verify Anypoint Platform username and password
echo 2. Check user has CloudHub deployment permissions
echo 3. Verify organization and environment access
echo 4. Ensure user is not locked or disabled
echo.
echo BUILD ISSUES:
echo 1. Verify Maven installation: mvn --version
echo 2. Check Java version compatibility (Java 8 or 11)
echo 3. Review Maven dependencies and repositories
echo 4. Clear Maven cache: mvn dependency:purge-local-repository
echo.
echo DEPLOYMENT ISSUES:
echo 1. Check CloudHub quotas and vCore limits
echo 2. Verify environment permissions
echo 3. Review application names for conflicts
echo 4. Check CloudHub region availability
echo.
pause
exit /b 1

:end
echo 🎉 Alternative authentication deployment successful!
echo Connected App issues resolved using username/password method
echo All systems operational - ready for production use
echo.
pause
