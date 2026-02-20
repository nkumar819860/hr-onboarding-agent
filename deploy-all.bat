@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

echo ========================================
echo 🚀 HR ONBOARDING AGENT - MULTI DEPLOY
echo ========================================

REM Check for deployment target parameter
if "%1"=="" (
    echo Usage: deploy-all.bat [docker^|cloud^|both]
    echo.
    echo  docker - Deploy to Docker Compose locally
    echo  cloud  - Deploy to Anypoint CloudHub
    echo  both   - Deploy to both environments
    echo.
    pause
    exit /b 1
)

set DEPLOY_TARGET=%1
echo Deployment Target: %DEPLOY_TARGET%
echo.

REM ========================================
REM 0. LOAD ENVIRONMENT VARIABLES
REM ========================================
echo [INFO] Loading environment variables from .env file...
if exist .env (
    for /f "usebackq tokens=1,2 delims==" %%a in (.env) do (
        if not "%%a"=="" if not "%%b"=="" (
            set "%%a=%%b"
        )
    )
    echo [✅] Environment variables loaded from .env
) else (
    echo [❌] .env file not found! Creating template...
    call :create_env_template
    echo [INFO] Please update .env file with your credentials and run again.
    pause
    exit /b 1
)

REM ========================================
REM 1. DOCKER COMPOSE DEPLOYMENT
REM ========================================
if "%DEPLOY_TARGET%"=="docker" (
    call :deploy_docker
) else if "%DEPLOY_TARGET%"=="both" (
    call :deploy_docker
)

REM ========================================
REM 2. CLOUDHUB DEPLOYMENT
REM ========================================
if "%DEPLOY_TARGET%"=="cloud" (
    call :deploy_cloud
) else if "%DEPLOY_TARGET%"=="both" (
    call :deploy_cloud
)

echo.
echo ========================================
echo ✅ DEPLOYMENT COMPLETED!
echo ========================================
pause
exit /b 0

REM ========================================
REM DOCKER DEPLOYMENT FUNCTION
REM ========================================
:deploy_docker
echo.
echo [DOCKER] 🐳 Starting Docker Compose deployment...
echo.

REM Check if Docker is running
docker --version >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo [❌] Docker not found or not running
    echo [FIX] Install Docker Desktop: https://docker.com/products/docker-desktop
    exit /b 1
)

echo [1/4] Building Docker images...
docker-compose build

echo [2/4] Starting services...
docker-compose up -d

echo [3/4] Waiting for services to start...
timeout /t 30 /nobreak >nul

echo [4/4] Checking service health...
docker-compose ps

echo.
echo [✅] Docker deployment completed!
echo.
echo 🌐 Local Endpoints:
echo   Agent Fabric:     http://localhost:8080/agent/health
echo   Employee MCP:     http://localhost:8081/mcp/health
echo   Asset MCP:        http://localhost:8082/mcp/health
echo   Notification MCP: http://localhost:8083/mcp/health
echo.

goto :eof

REM ========================================
REM CLOUDHUB DEPLOYMENT FUNCTION
REM ========================================
:deploy_cloud
echo.
echo [CLOUD] ☁️ Starting CloudHub deployment...
echo.

REM Validate Anypoint CLI
anypoint-cli-v4 --version >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo [❌] Anypoint CLI v4 not found!
    echo [FIX] Install: npm install -g anypoint-cli-v4
    exit /b 1
)

REM Check CLI configuration
if "%ANYPOINT_CLIENT_ID%"=="" (
    echo [❌] ANYPOINT_CLIENT_ID not set in .env file
    exit /b 1
)

if "%ANYPOINT_CLIENT_SECRET%"=="" (
    echo [❌] ANYPOINT_CLIENT_SECRET not set in .env file
    exit /b 1
)

echo [✅] Anypoint CLI configured

REM Deploy Employee Onboarding MCP
echo.
echo [1/3] 👤 Deploying Employee Onboarding MCP...
cd employee-onboarding-mcp
call mvn clean package -DskipTests=true -B -q
if !ERRORLEVEL! neq 0 (
    echo [❌] Employee MCP build failed!
    cd ..
    exit /b 1
)

anypoint-cli-v4 runtime-mgr cloudhub-application deploy ^
  "employee-onboarding-mcp-server" ^
  "target\employee-onboarding-mcp-server-1.0.1-mule-application.jar" ^
  --environment "%ANYPOINT_ENV%" ^
  --worker "Micro" ^
  --workers 1 ^
  --region "us-east-1" ^
  --timeout 300 ^
  --client-id "%ANYPOINT_CLIENT_ID%" ^
  --client-secret "%ANYPOINT_CLIENT_SECRET%"

if !ERRORLEVEL! neq 0 (
    echo [❌] Employee MCP deployment failed!
    cd ..
    exit /b 1
)
cd ..
echo [✅] Employee MCP deployed successfully

REM Deploy Asset Allocation MCP
echo.
echo [2/3] 💼 Deploying Asset Allocation MCP...
cd asset-allocation-mcp
call mvn clean package -DskipTests=true -B -q
if !ERRORLEVEL! neq 0 (
    echo [❌] Asset MCP build failed!
    cd ..
    exit /b 1
)

anypoint-cli-v4 runtime-mgr cloudhub-application deploy ^
  "asset-allocation-mcp-server" ^
  "target\asset-allocation-mcp-server-1.0.0-mule-application.jar" ^
  --environment "%ANYPOINT_ENV%" ^
  --worker "Micro" ^
  --workers 1 ^
  --region "us-east-1" ^
  --timeout 300 ^
  --client-id "%ANYPOINT_CLIENT_ID%" ^
  --client-secret "%ANYPOINT_CLIENT_SECRET%"

if !ERRORLEVEL! neq 0 (
    echo [❌] Asset MCP deployment failed!
    cd ..
    exit /b 1
)
cd ..
echo [✅] Asset MCP deployed successfully

REM Deploy Agent Fabric
echo.
echo [3/3] 🕸️ Deploying Agent Fabric...
cd agent-fabric
call mvn clean package -DskipTests=true -B -q
if !ERRORLEVEL! neq 0 (
    echo [❌] Agent Fabric build failed!
    cd ..
    exit /b 1
)

anypoint-cli-v4 runtime-mgr cloudhub-application deploy ^
  "hr-onboarding-agent-fabric" ^
  "target\hr-onboarding-agent-fabric-1.0.0-mule-application.jar" ^
  --environment "%ANYPOINT_ENV%" ^
  --worker "Micro" ^
  --workers 1 ^
  --region "us-east-1" ^
  --timeout 300 ^
  --client-id "%ANYPOINT_CLIENT_ID%" ^
  --client-secret "%ANYPOINT_CLIENT_SECRET%"

if !ERRORLEVEL! neq 0 (
    echo [❌] Agent Fabric deployment failed!
    cd ..
    exit /b 1
)
cd ..
echo [✅] Agent Fabric deployed successfully

echo.
echo [✅] CloudHub deployment completed!
echo.
echo ☁️ CloudHub Endpoints:
echo   Agent Fabric:     https://hr-onboarding-agent-fabric.us-east-1.cloudhub.io/agent/health
echo   Employee MCP:     https://employee-onboarding-mcp-server.us-east-1.cloudhub.io/mcp/health
echo   Asset MCP:        https://asset-allocation-mcp-server.us-east-1.cloudhub.io/mcp/health
echo.

goto :eof

REM ========================================
REM CREATE ENV TEMPLATE FUNCTION
REM ========================================
:create_env_template
echo # HR Onboarding Agent - Environment Configuration > .env
echo. >> .env
echo # Anypoint Platform Connected App Credentials >> .env
echo ANYPOINT_CLIENT_ID=your-connected-app-client-id >> .env
echo ANYPOINT_CLIENT_SECRET=your-connected-app-client-secret >> .env
echo ANYPOINT_ORG_ID=your-organization-id >> .env
echo ANYPOINT_ENV=Sandbox >> .env
echo. >> .env
echo # Application Names >> .env
echo AGENT_FABRIC_NAME=hr-onboarding-agent-fabric >> .env
echo EMPLOYEE_MCP_NAME=employee-onboarding-mcp-server >> .env
echo ASSET_MCP_NAME=asset-allocation-mcp-server >> .env
echo NOTIFICATION_MCP_NAME=notification-mcp-server >> .env
echo. >> .env
echo # Docker Configuration >> .env
echo DOCKER_REGISTRY=your-docker-registry >> .env
echo DOCKER_TAG=latest >> .env
echo. >> .env
echo # Database Configuration >> .env
echo DB_MODE=h2 >> .env
echo POSTGRES_URL=jdbc:postgresql://localhost:5432/hr_onboarding >> .env
echo POSTGRES_USER=postgres >> .env
echo POSTGRES_PASSWORD=password >> .env
goto :eof
