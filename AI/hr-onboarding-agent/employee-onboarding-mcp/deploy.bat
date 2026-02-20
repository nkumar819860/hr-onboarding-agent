@echo off
setlocal enabledelayedexpansion
echo ========================================
echo 🚀 EMPLOYEE ONBOARDING MCP - LIVE DEPLOY
echo ========================================

REM ========================================
REM 0. LOAD .ENV FILE
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
    echo [⚠️] .env file not found, using system environment variables
)

REM ========================================
REM 1. CHECK CONNECTED APP CREDENTIALS
REM ========================================
if "%ANYPOINT_CLIENT_ID%"=="" (
    echo [❌] ANYPOINT_CLIENT_ID not set!
    echo [FIX] Set environment variables for Connected App:
    echo   set ANYPOINT_CLIENT_ID=your-client-id
    echo   set ANYPOINT_CLIENT_SECRET=your-client-secret
    echo   set ANYPOINT_ORG_ID=your-org-id
    pause
    exit /b 1
)

if "%ANYPOINT_CLIENT_SECRET%"=="" (
    echo [❌] ANYPOINT_CLIENT_SECRET not set!
    echo [FIX] Set environment variables for Connected App:
    echo   set ANYPOINT_CLIENT_ID=your-client-id
    echo   set ANYPOINT_CLIENT_SECRET=your-client-secret
    echo   set ANYPOINT_ORG_ID=your-org-id
    pause
    exit /b 1
)

if "%ANYPOINT_ORG_ID%"=="" (
    echo [❌] ANYPOINT_ORG_ID not set!
    echo [FIX] Set environment variables for Connected App:
    echo   set ANYPOINT_CLIENT_ID=your-client-id
    echo   set ANYPOINT_CLIENT_SECRET=your-client-secret
    echo   set ANYPOINT_ORG_ID=your-org-id
    pause
    exit /b 1
)

echo [✅] Connected App credentials configured

REM ========================================
REM 1. BUILD JAR (WORKS 100%)
REM ========================================
echo [1/3] Building MCP Server...
mvn clean package -DskipTests=true

if %ERRORLEVEL% neq 0 (
    echo [❌] BUILD FAILED - Fix pom.xml first
    pause
    exit /b 1
)

REM Find exact JAR
set JAR=
for %%i in (target\*-mule-application.jar) do set JAR=%%i

if "%JAR%"=="" (
    echo [❌] JAR not found in target folder!
    dir target\*.jar
    pause
    exit /b 1
)

for %%A in ("%JAR%") do set JAR_SIZE=%%~zA
echo [✅] JAR Created: %JAR% (%JAR_SIZE% bytes)

REM ========================================
REM 2. DEPLOY TO CLOUDHUB AUTOMATICALLY
REM ========================================
echo.
echo [2/3] 🚀 DEPLOYING TO CLOUDHUB...

REM Deploy using Maven plugin with Connected App
echo [INFO] Deploying to CloudHub using Connected App...
mvn deploy -DmuleDeploy ^
  -Dconnected.app.client.id=%ANYPOINT_CLIENT_ID% ^
  -Dconnected.app.client.secret=%ANYPOINT_CLIENT_SECRET% ^
  -Danypoint.org.id=%ANYPOINT_ORG_ID%

if %ERRORLEVEL% neq 0 (
    echo.
    echo [❌] DEPLOYMENT FAILED! 
    echo.
    echo 🛠️ MANUAL DEPLOY OPTION:
    echo 1. Open: https://anypoint.mulesoft.com/cloudhub/#/applications
    echo 2. Click "CREATE APPLICATION" 
    echo 3. Name: employee-onboarding-mcp-server
    echo 4. Environment: Sandbox
    echo 5. Upload: %JAR%
    echo 6. Click DEPLOY
    echo.
    start "" "https://anypoint.mulesoft.com/cloudhub/#/applications"
    pause
    exit /b 1
)

REM ========================================
REM 3. DEPLOYMENT SUCCESS
REM ========================================
echo.
echo [3/3] ✅ DEPLOYMENT SUCCESSFUL!
echo.
echo 🎉 APPLICATION LIVE ON CLOUDHUB!
echo.
echo ========================================
echo 📍 LIVE ENDPOINTS:
echo ========================================
echo 🏥 Health:     https://employee-onboarding-mcp-server.us-east-1.cloudhub.io/mcp/health
echo 📚 API Docs:   https://employee-onboarding-mcp-server.us-east-1.cloudhub.io/mcp/api  
echo 👥 Employees:  https://employee-onboarding-mcp-server.us-east-1.cloudhub.io/mcp/tools/employees
echo.
echo 🧪 TEST: curl "https://employee-onboarding-mcp-server.us-east-1.cloudhub.io/mcp/health"
echo ========================================
pause
