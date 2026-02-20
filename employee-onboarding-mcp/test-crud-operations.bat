@echo off
echo ========================================
echo TESTING EMPLOYEE ONBOARDING CRUD OPERATIONS
echo ========================================

set BASE_URL=https://employee-onboarding-mcp-server-0etp45.rajrd4-1.usa-e1.cloudhub.io

echo.
echo [1] Testing Health Check...
curl -X GET %BASE_URL%/mcp/health
echo.
echo.

echo [2] Testing API Documentation...
curl -X GET %BASE_URL%/mcp/api
echo.
echo.

echo [3] Testing CREATE Employee (POST)...
curl -X POST %BASE_URL%/mcp/tools/employees ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"John Doe\", \"email\": \"john.doe@company.com\", \"department\": \"IT\", \"position\": \"Developer\"}"
echo.
echo.

echo [4] Testing CREATE Another Employee (POST)...
curl -X POST %BASE_URL%/mcp/tools/employees ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Jane Smith\", \"email\": \"jane.smith@company.com\", \"department\": \"HR\", \"position\": \"Manager\"}"
echo.
echo.

echo [5] Testing GET All Employees (GET)...
curl -X GET %BASE_URL%/mcp/tools/employees
echo.
echo.

echo [6] Testing GET Employee by ID (GET)...
curl -X GET %BASE_URL%/mcp/tools/employees/1
echo.
echo.

echo [7] Testing UPDATE Employee (PUT)...
curl -X PUT %BASE_URL%/mcp/tools/employees/1 ^
  -H "Content-Type: application/json" ^
  -d "{\"status\": \"active\", \"position\": \"Senior Developer\"}"
echo.
echo.

echo [8] Testing CREATE Asset for Employee (POST)...
curl -X POST %BASE_URL%/mcp/tools/employees/1/assets ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Laptop Dell XPS\", \"type\": \"equipment\", \"status\": \"assigned\"}"
echo.
echo.

echo [9] Testing CREATE Another Asset (POST)...
curl -X POST %BASE_URL%/mcp/tools/employees/1/assets ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Office Chair\", \"type\": \"furniture\", \"status\": \"assigned\"}"
echo.
echo.

echo [10] Testing GET Assets for Employee (GET)...
curl -X GET %BASE_URL%/mcp/tools/employees/1/assets
echo.
echo.

echo [11] Testing GET Updated Employee (Verify onboarding complete)...
curl -X GET %BASE_URL%/mcp/tools/employees/1
echo.
echo.

echo [12] Testing DELETE Employee (DELETE)...
curl -X DELETE %BASE_URL%/mcp/tools/employees/2
echo.
echo.

echo [13] Verify Deleted Employee (Should return not found)...
curl -X GET %BASE_URL%/mcp/tools/employees/2
echo.
echo.

echo [14] Final - GET All Employees (Should show remaining employees)...
curl -X GET %BASE_URL%/mcp/tools/employees
echo.
echo.

echo ========================================
echo CRUD OPERATIONS TESTING COMPLETED
echo ========================================
pause
