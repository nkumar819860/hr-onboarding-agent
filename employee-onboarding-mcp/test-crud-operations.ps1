# Employee Onboarding CRUD Operations Test Script
$BASE_URL = "https://employee-onboarding-mock-db-0etp45.rajrd4-2.usa-e1.cloudhub.io"

Write-Host "========================================" -ForegroundColor Green
Write-Host "TESTING EMPLOYEE ONBOARDING CRUD OPERATIONS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Step 0: Initialize Database
Write-Host "[0] Initializing H2 Database..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/init" -Method POST -ContentType "application/json"
    Write-Host "Database initialization result: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Database initialization error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 1: Health Check
Write-Host "[1] Testing Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/health" -Method GET
    Write-Host "Health Check Result: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Health Check Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 2: API Documentation
Write-Host "[2] Testing API Documentation..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/api" -Method GET
    Write-Host "API Documentation loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "API Documentation Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 3: Create Employee
Write-Host "[3] Testing CREATE Employee (POST)..." -ForegroundColor Yellow
$employee1 = @{
    name = "John Doe"
    email = "john.doe@company.com"
    department = "IT"
    position = "Developer"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees" -Method POST -Body $employee1 -ContentType "application/json"
    Write-Host "Employee Created: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Create Employee Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 4: Create Another Employee
Write-Host "[4] Testing CREATE Another Employee (POST)..." -ForegroundColor Yellow
$employee2 = @{
    name = "Jane Smith"
    email = "jane.smith@company.com"
    department = "HR"
    position = "Manager"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees" -Method POST -Body $employee2 -ContentType "application/json"
    Write-Host "Employee Created: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Create Employee Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 5: Get All Employees
Write-Host "[5] Testing GET All Employees (GET)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees" -Method GET
    Write-Host "All Employees: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Green
} catch {
    Write-Host "Get All Employees Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 6: Get Employee by ID
Write-Host "[6] Testing GET Employee by ID (GET)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees/1" -Method GET
    Write-Host "Employee by ID: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Green
} catch {
    Write-Host "Get Employee by ID Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 7: Update Employee
Write-Host "[7] Testing UPDATE Employee (PUT)..." -ForegroundColor Yellow
$updateData = @{
    status = "active"
    position = "Senior Developer"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees/1" -Method PUT -Body $updateData -ContentType "application/json"
    Write-Host "Employee Updated: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Update Employee Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 8: Create Asset for Employee
Write-Host "[8] Testing CREATE Asset for Employee (POST)..." -ForegroundColor Yellow
$asset1 = @{
    name = "Laptop Dell XPS"
    type = "equipment"
    status = "assigned"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees/1/assets" -Method POST -Body $asset1 -ContentType "application/json"
    Write-Host "Asset Created: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Create Asset Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 9: Create Another Asset
Write-Host "[9] Testing CREATE Another Asset (POST)..." -ForegroundColor Yellow
$asset2 = @{
    name = "Office Chair"
    type = "furniture"
    status = "assigned"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees/1/assets" -Method POST -Body $asset2 -ContentType "application/json"
    Write-Host "Asset Created: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Create Asset Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 10: Get Assets for Employee
Write-Host "[10] Testing GET Assets for Employee (GET)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees/1/assets" -Method GET
    Write-Host "Employee Assets: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Green
} catch {
    Write-Host "Get Employee Assets Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 11: Get Updated Employee (should show onboarding complete)
Write-Host "[11] Testing GET Updated Employee (Verify onboarding complete)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees/1" -Method GET
    Write-Host "Updated Employee: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Green
} catch {
    Write-Host "Get Updated Employee Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 12: Delete Employee
Write-Host "[12] Testing DELETE Employee (DELETE)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees/2" -Method DELETE
    Write-Host "Employee Deleted: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Delete Employee Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Step 13: Verify Deleted Employee
Write-Host "[13] Verify Deleted Employee (Should return not found)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees/2" -Method GET
    Write-Host "Unexpected - Employee still exists: $($response | ConvertTo-Json)" -ForegroundColor Red
} catch {
    Write-Host "Expected - Employee not found: $($_.Exception.Message)" -ForegroundColor Green
}
Write-Host ""

# Step 14: Final - Get All Employees
Write-Host "[14] Final - GET All Employees (Should show remaining employees)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/mcp/tools/employees" -Method GET
    Write-Host "Final Employee List: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Green
} catch {
    Write-Host "Final Get All Employees Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "CRUD OPERATIONS TESTING COMPLETED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Read-Host "Press Enter to continue..."
