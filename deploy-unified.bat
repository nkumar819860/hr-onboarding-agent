@echo off
setlocal enabledelayedexpansion

:: HR Onboarding Agent - Unified Deployment Script
:: Supports CloudHub and Docker deployment with toggle

echo ===============================================
echo    HR Onboarding Agent Deployment Script
echo ===============================================
echo.

:: Check for deployment mode argument
set DEPLOY_MODE=%1
if "%DEPLOY_MODE%"=="" (
    echo Usage: deploy-unified.bat [cloudhub^|docker^|both] [environment]
    echo.
    echo Deployment Modes:
    echo   cloudhub  - Deploy to CloudHub 2.0
    echo   docker    - Deploy with Docker Compose
    echo   both      - Deploy to both CloudHub and Docker
    echo.
    echo Environments ^(CloudHub only^):
    echo   sandbox   - Deploy to Sandbox environment ^(default^)
    echo   production- Deploy to Production environment
    echo.
    echo Examples:
    echo   deploy-unified.bat docker
    echo   deploy-unified.bat cloudhub sandbox
    echo   deploy-unified.bat both production
    pause
    exit /b 1
)

:: Set environment (default to sandbox)
set ENVIRONMENT=%2
if "%ENVIRONMENT%"=="" set ENVIRONMENT=sandbox

echo Deployment Mode: %DEPLOY_MODE%
echo Environment: %ENVIRONMENT%
echo.

:: Configuration variables
set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

:: CloudHub Configuration
set CLOUDHUB_ORG=your-org-id
set CLOUDHUB_ENV=%ENVIRONMENT%
set CLOUDHUB_REGION=us-east-1

:: MCP Services Configuration
set EMPLOYEE_MCP=employee-onboarding-mcp
set ASSET_MCP=asset-allocation-mcp
set NOTIFICATION_MCP=notification-mcp
set AGENT_FABRIC=agent-fabric

:: Docker Configuration
set DOCKER_COMPOSE_FILE=docker-compose.yml

:: Function to check if MuleSoft CLI is installed
echo Checking prerequisites...
call :check_prerequisites
if errorlevel 1 exit /b 1

:: Main deployment logic
if /i "%DEPLOY_MODE%"=="docker" (
    call :deploy_docker
) else if /i "%DEPLOY_MODE%"=="cloudhub" (
    call :deploy_cloudhub
) else if /i "%DEPLOY_MODE%"=="both" (
    call :deploy_docker
    if errorlevel 1 (
        echo ERROR: Docker deployment failed. Skipping CloudHub deployment.
        exit /b 1
    )
    call :deploy_cloudhub
) else (
    echo ERROR: Invalid deployment mode: %DEPLOY_MODE%
    exit /b 1
)

echo.
echo ===============================================
echo    Deployment Completed Successfully!
echo ===============================================
exit /b 0

:: ===============================================
:: FUNCTIONS
:: ===============================================

:check_prerequisites
echo [INFO] Checking prerequisites...

:: Check if Docker is available for Docker deployment
if /i "%DEPLOY_MODE%"=="docker" or /i "%DEPLOY_MODE%"=="both" (
    docker --version >nul 2>&1
    if errorlevel 1 (
        echo ERROR: Docker is not installed or not in PATH
        echo Please install Docker Desktop and try again
        exit /b 1
    )
    echo [OK] Docker is available
)

:: Check if MuleSoft CLI is available for CloudHub deployment
if /i "%DEPLOY_MODE%"=="cloudhub" or /i "%DEPLOY_MODE%"=="both" (
    anypoint-cli --version >nul 2>&1
    if errorlevel 1 (
        echo ERROR: Anypoint CLI is not installed or not in PATH
        echo Please install Anypoint CLI and try again
        echo Download from: https://docs.mulesoft.com/anypoint-cli/4.x/
        exit /b 1
    )
    echo [OK] Anypoint CLI is available
)

:: Check if Maven is available
mvn --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Maven is not installed or not in PATH
    echo Please install Maven and try again
    exit /b 1
)
echo [OK] Maven is available

exit /b 0

:deploy_docker
echo.
echo ===============================================
echo    DOCKER DEPLOYMENT
echo ===============================================

:: Configure MCP services for Docker deployment
echo [INFO] Configuring MCP services for Docker deployment...
call :configure_mcp_for_docker

:: Stop any existing containers
echo [INFO] Stopping existing containers...
docker-compose -f %DOCKER_COMPOSE_FILE% down

:: Build and start services
echo [INFO] Building and starting Docker services...
docker-compose -f %DOCKER_COMPOSE_FILE% up --build -d

if errorlevel 1 (
    echo ERROR: Docker deployment failed
    exit /b 1
)

:: Wait for services to start
echo [INFO] Waiting for services to start...
timeout /t 30 /nobreak

:: Check service health
echo [INFO] Checking service health...
call :check_docker_health

echo [SUCCESS] Docker deployment completed successfully!
echo.
echo Services available at:
echo   - Employee MCP: http://localhost:8081
echo   - Asset MCP: http://localhost:8084  
echo   - Notification MCP: http://localhost:8085
echo   - MCP Client: http://localhost:3000
echo   - Agent Fabric: http://localhost:8080

exit /b 0

:deploy_cloudhub
echo.
echo ===============================================
echo    CLOUDHUB DEPLOYMENT
echo ===============================================

:: Configure MCP services for CloudHub deployment
echo [INFO] Configuring MCP services for CloudHub deployment...
call :configure_mcp_for_cloudhub

:: Login to Anypoint Platform (if not already logged in)
echo [INFO] Authenticating with Anypoint Platform...
anypoint-cli auth:login --help >nul 2>&1
if errorlevel 1 (
    echo Please login to Anypoint Platform:
    anypoint-cli auth:login
    if errorlevel 1 (
        echo ERROR: Failed to authenticate with Anypoint Platform
        exit /b 1
    )
)

:: Deploy each MCP service
echo [INFO] Deploying MCP services to CloudHub...

call :deploy_mcp_service %EMPLOYEE_MCP% employee-onboarding-mcp-server-%ENVIRONMENT%
if errorlevel 1 exit /b 1

call :deploy_mcp_service %ASSET_MCP% asset-allocation-mcp-server-%ENVIRONMENT%
if errorlevel 1 exit /b 1

call :deploy_mcp_service %NOTIFICATION_MCP% notification-mcp-server-%ENVIRONMENT%
if errorlevel 1 exit /b 1

call :deploy_mcp_service %AGENT_FABRIC% hr-onboarding-agent-fabric-%ENVIRONMENT%
if errorlevel 1 exit /b 1

echo [SUCCESS] CloudHub deployment completed successfully!
echo.
echo Applications deployed to CloudHub environment: %ENVIRONMENT%
echo Monitor deployments at: https://anypoint.mulesoft.com/runtime-manager/

exit /b 0

:configure_mcp_for_docker
echo [INFO] Configuring services for Docker deployment...

:: Update database mode to H2 for Docker
call :update_config_property %EMPLOYEE_MCP%\src\main\resources\config.properties "db.mode" "h2"
call :update_config_property %ASSET_MCP%\src\main\resources\config.properties "db.mode" "h2"  
call :update_config_property %NOTIFICATION_MCP%\src\main\resources\config.properties "db.mode" "h2"

echo [OK] Services configured for Docker deployment
exit /b 0

:configure_mcp_for_cloudhub
echo [INFO] Configuring services for CloudHub deployment...

:: Update database mode based on environment
if /i "%ENVIRONMENT%"=="production" (
    set DB_MODE=postgres
) else (
    set DB_MODE=h2
)

call :update_config_property %EMPLOYEE_MCP%\src\main\resources\config.properties "db.mode" "!DB_MODE!"
call :update_config_property %ASSET_MCP%\src\main\resources\config.properties "db.mode" "!DB_MODE!"
call :update_config_property %NOTIFICATION_MCP%\src\main\resources\config.properties "db.mode" "!DB_MODE!"

echo [OK] Services configured for CloudHub deployment with DB mode: !DB_MODE!
exit /b 0

:deploy_mcp_service
set SERVICE_DIR=%1
set APP_NAME=%2

echo [INFO] Deploying %SERVICE_DIR% as %APP_NAME%...

:: Build the service
pushd %SERVICE_DIR%
echo [INFO] Building %SERVICE_DIR%...
mvn clean package -DskipTests -q
if errorlevel 1 (
    echo ERROR: Failed to build %SERVICE_DIR%
    popd
    exit /b 1
)

:: Deploy to CloudHub using Anypoint CLI
echo [INFO] Deploying %APP_NAME% to CloudHub...
anypoint-cli runtime-mgr cloudhub-application deploy ^
    --environment %CLOUDHUB_ENV% ^
    --target CloudHub-US-East-1 ^
    --runtime 4.9.4 ^
    --applicationName %APP_NAME% ^
    --file target\%SERVICE_DIR%-1.0.0-SNAPSHOT-mule-application.jar ^
    --replicas 1 ^
    --replicaSize mule.nano ^
    --property "anypoint.platform.config.analytics.agent.enabled=true"

if errorlevel 1 (
    echo ERROR: Failed to deploy %APP_NAME% to CloudHub
    popd
    exit /b 1
)

popd
echo [OK] %APP_NAME% deployed successfully
exit /b 0

:check_docker_health
echo [INFO] Checking Docker service health...

:: Check if services are running
for %%s in (employee-mcp asset-mcp notification-mcp mcp-client) do (
    docker ps | findstr %%s >nul
    if errorlevel 1 (
        echo WARNING: Service %%s may not be running properly
    ) else (
        echo [OK] Service %%s is running
    )
)
exit /b 0

:update_config_property
set CONFIG_FILE=%1
set PROPERTY_NAME=%2
set PROPERTY_VALUE=%3

if not exist "%CONFIG_FILE%" (
    echo WARNING: Config file not found: %CONFIG_FILE%
    exit /b 0
)

:: Create a temporary file with updated property
set TEMP_FILE=%CONFIG_FILE%.tmp

(
    for /f "tokens=1,* delims==" %%a in ('type "%CONFIG_FILE%"') do (
        if "%%a"=="%PROPERTY_NAME%" (
            echo %PROPERTY_NAME%=%PROPERTY_VALUE%
        ) else (
            echo %%a=%%b
        )
    )
) > "%TEMP_FILE%"

:: Replace original file
move "%TEMP_FILE%" "%CONFIG_FILE%" >nul
echo [OK] Updated %PROPERTY_NAME% in %CONFIG_FILE%
exit /b 0
