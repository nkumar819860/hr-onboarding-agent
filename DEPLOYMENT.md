# HR Onboarding Agent - Deployment Guide

This guide provides comprehensive instructions for deploying the HR Onboarding Agent system using the unified deployment scripts.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [System Architecture](#system-architecture)
- [Database Configuration](#database-configuration)
- [Deployment Options](#deployment-options)
- [Deployment Scripts Usage](#deployment-scripts-usage)
- [Environment Configuration](#environment-configuration)
- [Troubleshooting](#troubleshooting)
- [Monitoring and Health Checks](#monitoring-and-health-checks)

## Overview

The HR Onboarding Agent system consists of:

- **Employee Onboarding MCP Server** - Core employee management services
- **Asset Allocation MCP Server** - Asset management and allocation services  
- **Notification MCP Server** - Email and notification services
- **Agent Fabric** - Integration and orchestration layer
- **MCP Client** - React-based user interface

## Prerequisites

### For Docker Deployment
- Docker Desktop 4.0+ 
- Docker Compose 2.0+
- Maven 3.6+
- Java 8 or 11

### For CloudHub Deployment
- Anypoint CLI 4.x ([Download](https://docs.mulesoft.com/anypoint-cli/4.x/))
- Valid Anypoint Platform account
- Maven 3.6+
- Java 8 or 11
- Access to CloudHub environment

### System Requirements
- **Memory**: Minimum 8GB RAM (16GB recommended)
- **Storage**: 10GB free space
- **Network**: Internet connection for CloudHub deployment

## System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MCP Client    │    │  Agent Fabric   │    │  External APIs  │
│   (React App)   │    │ (Orchestration) │    │                 │
│   Port: 3000    │    │   Port: 8080    │    │                 │
└─────────┬───────┘    └─────────┬───────┘    └─────────────────┘
          │                      │
          └──────────┬───────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
┌───▼───┐       ┌────▼───┐       ┌───▼───┐
│Employee│       │ Asset  │       │Notify │
│  MCP   │       │  MCP   │       │ MCP   │
│ :8081  │       │ :8084  │       │ :8085 │
└───┬───┘       └────┬───┘       └───┬───┘
    │                │               │
┌───▼───┐       ┌────▼───┐       ┌───▼───┐
│   H2   │       │   H2   │       │   H2  │
│Database│       │Database│       │Database│
└───────┘       └────────┘       └───────┘
```

## Database Configuration

The system supports multiple database configurations:

### Database Modes

1. **H2 Database** (`db.mode=h2`)
   - Embedded database
   - Best for development and testing
   - No external dependencies
   - Data persisted to local files

2. **PostgreSQL** (`db.mode=postgres`) 
   - Production-grade database
   - Recommended for production environments
   - Requires external PostgreSQL server
   - Better performance and scalability

3. **Mock Mode** (`db.mode=mock`)
   - Returns predefined mock responses
   - Used when databases are unavailable
   - Automatic fallback mechanism

### Database Fallback Strategy

1. **Primary Database** - Configured based on `db.mode` setting
2. **Fallback H2** - If primary database fails, falls back to local H2
3. **Mock Responses** - If all databases fail, returns mock data

## Deployment Options

### 1. Docker Deployment (Recommended for Development)

**Advantages:**
- Quick setup and deployment
- Consistent environment across machines
- Easy local development
- All services containerized

**Use Cases:**
- Local development
- Testing
- Demo environments

### 2. CloudHub Deployment (Recommended for Production)

**Advantages:**
- Managed infrastructure
- Auto-scaling capabilities
- Built-in monitoring
- High availability

**Use Cases:**
- Production environments
- Staging environments
- Client demonstrations

### 3. Hybrid Deployment

Deploy to both Docker (for local testing) and CloudHub (for production) simultaneously.

## Deployment Scripts Usage

### Windows Batch Script

```batch
# Deploy to Docker only
deploy-unified.bat docker

# Deploy to CloudHub sandbox
deploy-unified.bat cloudhub sandbox

# Deploy to CloudHub production  
deploy-unified.bat cloudhub production

# Deploy to both Docker and CloudHub
deploy-unified.bat both sandbox
```

### PowerShell Script

```powershell
# Deploy to Docker only
.\deploy-unified.ps1 -DeployMode docker

# Deploy to CloudHub sandbox
.\deploy-unified.ps1 -DeployMode cloudhub -Environment sandbox

# Deploy to CloudHub production
.\deploy-unified.ps1 -DeployMode cloudhub -Environment production  

# Deploy to both Docker and CloudHub
.\deploy-unified.ps1 -DeployMode both -Environment sandbox
```

## Environment Configuration

### Docker Environment

The deployment script automatically configures services for Docker:

- Database mode: `h2` 
- Internal networking between containers
- Local file-based persistence
- Development-friendly settings

### CloudHub Environments

#### Sandbox Environment
- Database mode: `h2` (embedded)
- Nano worker size
- Basic monitoring enabled
- Cost-effective for testing

#### Production Environment  
- Database mode: `postgres` (external)
- Configurable worker size
- Enhanced monitoring
- High availability options

### Manual Configuration

Edit the `config.properties` files in each MCP service to customize:

```properties
# Database Configuration
db.mode=h2|postgres|mock

# H2 Database (Development)
db.h2.driver=org.h2.Driver
db.h2.url=jdbc:h2:file:./data/database_name
db.h2.user=sa
db.h2.password=

# PostgreSQL (Production)
db.postgres.driver=org.postgresql.Driver  
db.postgres.url=jdbc:postgresql://localhost:5432/database_name
db.postgres.user=postgres
db.postgres.password=password
```

## Deployment Process

### Pre-deployment Checklist

1. **Verify Prerequisites**
   - [ ] Docker Desktop installed and running (for Docker deployment)
   - [ ] Anypoint CLI installed and configured (for CloudHub deployment)
   - [ ] Maven installed and in PATH
   - [ ] Java 8 or 11 installed
   - [ ] Internet connection available

2. **Prepare Environment**
   - [ ] Clone/download project repository
   - [ ] Navigate to project root directory
   - [ ] Ensure all MCP services have proper configuration files

3. **Authentication** (CloudHub only)
   - [ ] Login to Anypoint Platform: `anypoint-cli auth:login`
   - [ ] Verify access to target environment

### Deployment Steps

1. **Choose Deployment Mode**
   ```bash
   # For development/testing
   deploy-unified.bat docker
   
   # For production
   deploy-unified.bat cloudhub production
   ```

2. **Monitor Deployment**
   - Watch console output for progress
   - Check for any error messages
   - Verify successful completion message

3. **Verify Deployment**
   - Check service endpoints
   - Run health checks
   - Test core functionality

### Post-deployment Verification

#### Docker Deployment
```bash
# Check container status
docker ps

# Check service logs
docker-compose logs employee-mcp
docker-compose logs asset-mcp
docker-compose logs notification-mcp

# Test endpoints
curl http://localhost:8081/health
curl http://localhost:8084/health  
curl http://localhost:8085/health
```

#### CloudHub Deployment
- Navigate to Anypoint Runtime Manager
- Verify all applications are in "Running" state
- Check application logs for any errors
- Test application endpoints

## Troubleshooting

### Common Issues

#### Docker Deployment Issues

**Port Conflicts**
```bash
# Check for port usage
netstat -an | findstr ":8081"
netstat -an | findstr ":8084"
netstat -an | findstr ":8085"

# Solution: Stop conflicting processes or change ports in docker-compose.yml
```

**Memory Issues**
```bash
# Increase Docker Desktop memory allocation
# Settings > Resources > Memory > 8GB+
```

**Build Failures**
```bash
# Clean Maven cache
mvn clean

# Rebuild specific service
cd employee-onboarding-mcp
mvn clean package -DskipTests
```

#### CloudHub Deployment Issues

**Authentication Problems**
```bash
# Re-authenticate
anypoint-cli auth:logout
anypoint-cli auth:login
```

**Deployment Failures**
- Check application logs in Runtime Manager
- Verify environment permissions
- Check resource quotas and limits

**Java Version Conflicts**
```
Error: Extension 'Validation' does not support Java 17
```
**Solution**: Ensure `mule-artifact.json` only includes Java 8 and 11:
```json
"javaSpecificationVersions": ["8", "11"]
```

### Database Issues

**H2 Database Lock**
```bash
# Delete lock files
rm -f data/*.lock.db
```

**PostgreSQL Connection Issues**
- Verify database server is running
- Check connection parameters in config.properties
- Ensure database and user exist

### Service Health Issues

**Service Not Responding**
1. Check service logs for errors
2. Verify database connectivity  
3. Check memory and CPU usage
4. Restart service if necessary

## Monitoring and Health Checks

### Built-in Health Endpoints

Each MCP service provides health check endpoints:

- Employee MCP: `http://localhost:8081/health`
- Asset MCP: `http://localhost:8084/health`  
- Notification MCP: `http://localhost:8085/health`

### System Health Dashboard

Access the enhanced SystemHealth component at `http://localhost:3000/system-health` for:

- Overall system health score
- Individual service status
- System metrics (CPU, Memory, Disk)
- Performance history
- Real-time alerts
- Auto-refresh capabilities

### Monitoring Best Practices

1. **Regular Health Checks**
   - Monitor service endpoints regularly
   - Set up automated health monitoring
   - Configure alerts for service failures

2. **Log Management**
   - Review application logs daily
   - Set up log aggregation for production
   - Monitor for error patterns

3. **Performance Monitoring**
   - Track response times
   - Monitor resource usage
   - Set up performance alerts

4. **Database Monitoring**
   - Monitor database connectivity
   - Track query performance
   - Monitor storage usage

## Security Considerations

### Docker Deployment
- Services communicate internally via Docker network
- Expose only necessary ports to host machine
- Use environment variables for sensitive configuration

### CloudHub Deployment  
- Leverage Anypoint Platform security features
- Use secure property placeholders for sensitive data
- Enable API security policies as needed
- Configure VPC if required for production

## Support and Maintenance

### Regular Maintenance Tasks

1. **Weekly**
   - Review system health metrics
   - Check for any performance issues
   - Update dependency versions if needed

2. **Monthly**
   - Review and clean log files
   - Check database performance
   - Verify backup procedures

3. **Quarterly**
   - Security updates
   - Performance optimization
   - Disaster recovery testing

### Getting Help

For deployment issues or questions:

1. Check this deployment guide
2. Review application logs
3. Check Anypoint Platform documentation
4. Contact system administrator

---

**Last Updated**: February 2026  
**Version**: 1.0.0
