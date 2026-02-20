# HR Onboarding Agent - Unified Deployment Script (PowerShell)
# Supports CloudHub and Docker deployment with toggle

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("cloudhub", "docker", "both")]
    [string]$DeployMode,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("sandbox", "production")]
    [string]$Environment = "sandbox"
)

# Script configuration
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Configuration variables
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# CloudHub Configuration
$CloudHubOrg = "your-org-id"
$CloudHubEnv = $Environment
$CloudHubRegion = "us-east-1"

# MCP Services Configuration
$MCPServices = @{
    "employee-onboarding-mcp" = "employee-onboarding-mcp-server-$Environment"
    "asset-allocation-mcp" = "asset-allocation-mcp-server-$Environment"
    "notification-mcp" = "notification-mcp-server-$Environment"
    "agent-fabric" = "hr-onboarding-agent-fabric-$Environment"
}

# Docker Configuration
$DockerComposeFile = "docker-compose.yml"

function Write-Header {
    param([string]$Title)
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "   $Title" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check Docker for Docker deployment
    if ($DeployMode -eq "docker" -or $DeployMode -eq "both") {
        try {
            $dockerVersion = docker --version 2>$null
            if ($LASTEXITCODE -ne 0) { throw "Docker command failed" }
            Write-Host "[OK] Docker is available: $dockerVersion" -ForegroundColor Green
        }
        catch {
            Write-Error "Docker is not installed or not in PATH"
            Write-Host "Please install Docker Desktop and try again" -ForegroundColor Red
            exit 1
        }
    }
    
    # Check Anypoint CLI for CloudHub deployment
    if ($DeployMode -eq "cloudhub" -or $DeployMode -eq "both") {
        try {
            $anypointVersion = anypoint-cli --version 2>$null
            if ($LASTEXITCODE -ne 0) { throw "Anypoint CLI command failed" }
            Write-Host "[OK] Anypoint CLI is available: $anypointVersion" -ForegroundColor Green
        }
        catch {
            Write-Error "Anypoint CLI is not installed or not in PATH"
            Write-Host "Please install Anypoint CLI and try again" -ForegroundColor Red
            Write-Host "Download from: https://docs.mulesoft.com/anypoint-cli/4.x/" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # Check Maven
    try {
        $mavenVersion = mvn --version 2>$null | Select-Object -First 1
        if ($LASTEXITCODE -ne 0) { throw "Maven command failed" }
        Write-Host "[OK] Maven is available: $mavenVersion" -ForegroundColor Green
    }
    catch {
        Write-Error "Maven is not installed or not in PATH"
        Write-Host "Please install Maven and try again" -ForegroundColor Red
        exit 1
    }
}

function Update-ConfigProperty {
    param(
        [string]$ConfigFile,
        [string]$PropertyName,
        [string]$PropertyValue
    )
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Warning "Config file not found: $ConfigFile"
        return
    }
    
    $content = Get-Content $ConfigFile
    $updatedContent = @()
    $propertyFound = $false
    
    foreach ($line in $content) {
        if ($line -match "^$PropertyName\s*=") {
            $updatedContent += "$PropertyName=$PropertyValue"
            $propertyFound = $true
        }
        else {
            $updatedContent += $line
        }
    }
    
    if (-not $propertyFound) {
        $updatedContent += "$PropertyName=$PropertyValue"
    }
    
    $updatedContent | Set-Content $ConfigFile
    Write-Host "[OK] Updated $PropertyName in $ConfigFile" -ForegroundColor Green
}

function Set-MCPConfigForDocker {
    Write-Info "Configuring services for Docker deployment..."
    
    Update-ConfigProperty -ConfigFile "employee-onboarding-mcp\src\main\resources\config.properties" -PropertyName "db.mode" -PropertyValue "h2"
    Update-ConfigProperty -ConfigFile "asset-allocation-mcp\src\main\resources\config.properties" -PropertyName "db.mode" -PropertyValue "h2"
    Update-ConfigProperty -ConfigFile "notification-mcp\src\main\resources\config.properties" -PropertyName "db.mode" -PropertyValue "h2"
    
    Write-Host "[OK] Services configured for Docker deployment" -ForegroundColor Green
}

function Set-MCPConfigForCloudHub {
    Write-Info "Configuring services for CloudHub deployment..."
    
    $dbMode = if ($Environment -eq "production") { "postgres" } else { "h2" }
    
    Update-ConfigProperty -ConfigFile "employee-onboarding-mcp\src\main\resources\config.properties" -PropertyName "db.mode" -PropertyValue $dbMode
    Update-ConfigProperty -ConfigFile "asset-allocation-mcp\src\main\resources\config.properties" -PropertyName "db.mode" -PropertyValue $dbMode
    Update-ConfigProperty -ConfigFile "notification-mcp\src\main\resources\config.properties" -PropertyName "db.mode" -PropertyValue $dbMode
    
    Write-Host "[OK] Services configured for CloudHub deployment with DB mode: $dbMode" -ForegroundColor Green
}

function Deploy-Docker {
    Write-Header "DOCKER DEPLOYMENT"
    
    # Configure MCP services for Docker
    Set-MCPConfigForDocker
    
    # Stop existing containers
    Write-Info "Stopping existing containers..."
    docker-compose -f $DockerComposeFile down
    
    # Build and start services
    Write-Info "Building and starting Docker services..."
    docker-compose -f $DockerComposeFile up --build -d
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker deployment failed"
        exit 1
    }
    
    # Wait for services to start
    Write-Info "Waiting for services to start..."
    Start-Sleep -Seconds 30
    
    # Check service health
    Test-DockerHealth
    
    Write-Success "Docker deployment completed successfully!"
    Write-Host ""
    Write-Host "Services available at:" -ForegroundColor Cyan
    Write-Host "  - Employee MCP: http://localhost:8081" -ForegroundColor White
    Write-Host "  - Asset MCP: http://localhost:8084" -ForegroundColor White
    Write-Host "  - Notification MCP: http://localhost:8085" -ForegroundColor White
    Write-Host "  - MCP Client: http://localhost:3000" -ForegroundColor White
    Write-Host "  - Agent Fabric: http://localhost:8080" -ForegroundColor White
}

function Deploy-CloudHub {
    Write-Header "CLOUDHUB DEPLOYMENT"
    
    # Configure MCP services for CloudHub
    Set-MCPConfigForCloudHub
    
    # Check authentication
    Write-Info "Checking Anypoint Platform authentication..."
    try {
        anypoint-cli conf --help >$null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Info "Please login to Anypoint Platform:"
            anypoint-cli auth:login
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to authenticate with Anypoint Platform"
                exit 1
            }
        }
    }
    catch {
        Write-Info "Please login to Anypoint Platform:"
        anypoint-cli auth:login
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to authenticate with Anypoint Platform"
            exit 1
        }
    }
    
    # Deploy each MCP service
    Write-Info "Deploying MCP services to CloudHub..."
    
    foreach ($service in $MCPServices.GetEnumerator()) {
        Deploy-MCPService -ServiceDir $service.Key -AppName $service.Value
    }
    
    Write-Success "CloudHub deployment completed successfully!"
    Write-Host ""
    Write-Host "Applications deployed to CloudHub environment: $Environment" -ForegroundColor Cyan
    Write-Host "Monitor deployments at: https://anypoint.mulesoft.com/runtime-manager/" -ForegroundColor Yellow
}

function Deploy-MCPService {
    param(
        [string]$ServiceDir,
        [string]$AppName
    )
    
    Write-Info "Deploying $ServiceDir as $AppName..."
    
    # Build the service
    Push-Location $ServiceDir
    try {
        Write-Info "Building $ServiceDir..."
        mvn clean package -DskipTests -q
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to build $ServiceDir"
            Pop-Location
            exit 1
        }
        
        # Get the JAR file name
        $jarFile = Get-ChildItem -Path "target" -Filter "*-mule-application.jar" | Select-Object -First 1
        if (-not $jarFile) {
            Write-Error "Could not find built JAR file for $ServiceDir"
            Pop-Location
            exit 1
        }
        
        # Deploy to CloudHub
        Write-Info "Deploying $AppName to CloudHub..."
        $deployCmd = @(
            "anypoint-cli", "runtime-mgr", "cloudhub-application", "deploy",
            "--environment", $CloudHubEnv,
            "--target", "CloudHub-US-East-1",
            "--runtime", "4.9.4",
            "--applicationName", $AppName,
            "--file", "target\$($jarFile.Name)",
            "--replicas", "1",
            "--replicaSize", "mule.nano",
            "--property", "anypoint.platform.config.analytics.agent.enabled=true"
        )
        
        & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)]
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to deploy $AppName to CloudHub"
            Pop-Location
            exit 1
        }
        
        Write-Host "[OK] $AppName deployed successfully" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

function Test-DockerHealth {
    Write-Info "Checking Docker service health..."
    
    $services = @("employee-mcp", "asset-mcp", "notification-mcp", "mcp-client")
    
    foreach ($service in $services) {
        $running = docker ps --filter "name=$service" --format "table {{.Names}}" | Select-String $service
        if ($running) {
            Write-Host "[OK] Service $service is running" -ForegroundColor Green
        }
        else {
            Write-Warning "Service $service may not be running properly"
        }
    }
}

# Main execution
try {
    Write-Header "HR Onboarding Agent Deployment Script"
    Write-Host "Deployment Mode: $DeployMode" -ForegroundColor Yellow
    Write-Host "Environment: $Environment" -ForegroundColor Yellow
    Write-Host ""
    
    # Check prerequisites
    Test-Prerequisites
    
    # Execute deployment based on mode
    switch ($DeployMode) {
        "docker" {
            Deploy-Docker
        }
        "cloudhub" {
            Deploy-CloudHub
        }
        "both" {
            Deploy-Docker
            Deploy-CloudHub
        }
    }
    
    Write-Header "Deployment Completed Successfully!"
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}
