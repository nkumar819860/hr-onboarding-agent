# HR Onboarding Agent

A comprehensive HR onboarding solution built with MuleSoft's Agent Fabric architecture, featuring multiple MCP (Model Context Protocol) servers for distributed employee onboarding management.

## 🏗️ Architecture

This project implements a microservices-based HR onboarding system with the following components:

### Core Services

- **Agent Fabric** (Port 8080) - Main orchestrator that coordinates all onboarding activities
- **Employee MCP** (Port 8081) - Manages employee data and onboarding records
- **Asset MCP** (Port 8082) - Handles asset allocation and tracking
- **Notification MCP** (Port 8083) - Manages notifications and communications

### Supporting Services

- **PostgreSQL Database** - Centralized data storage
- **Adminer** (Port 8090) - Database management interface

## 🚀 Quick Start

### Prerequisites

- **For Docker Deployment:**
  - Docker Desktop
  - Docker Compose

- **For CloudHub Deployment:**
  - Node.js (for Anypoint CLI)
  - Anypoint CLI v4: `npm install -g anypoint-cli-v4`
  - Anypoint Platform Connected App credentials

### 1. Environment Setup

```bash
# Copy environment template
copy .env.example .env

# Edit .env file with your credentials
# - Update Anypoint Platform Connected App details
# - Set database passwords
# - Configure other settings as needed
```

### 2. Local Development (Docker)

```bash
# Deploy all services locally
deploy-all.bat docker

# Access services:
# - Agent Fabric: http://localhost:8080/agent/health
# - Employee MCP: http://localhost:8081/mcp/health
# - Asset MCP: http://localhost:8082/mcp/health
# - Database UI: http://localhost:8090
```

### 3. Cloud Deployment (CloudHub)

```bash
# Configure Anypoint CLI with your Connected App
anypoint-cli-v4 conf client_id YOUR_CLIENT_ID
anypoint-cli-v4 conf client_secret YOUR_CLIENT_SECRET

# Deploy to CloudHub
deploy-all.bat cloud
```

### 4. Hybrid Deployment

```bash
# Deploy to both environments
deploy-all.bat both
```

## 📋 API Endpoints

### Agent Fabric (Main Orchestrator)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/agent/onboard` | Complete HR onboarding process |
| `GET` | `/agent/onboard/{employeeId}/status` | Check onboarding status |
| `GET` | `/agent/onboard/employees` | List all employees |
| `GET` | `/agent/health` | Agent fabric health check |

### Employee MCP

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/mcp/tools/employees` | Create new employee |
| `GET` | `/mcp/tools/employees` | Get all employees |
| `GET` | `/mcp/tools/employees/{id}` | Get employee by ID |
| `PUT` | `/mcp/tools/employees/{id}` | Update employee |
| `DELETE` | `/mcp/tools/employees/{id}` | Delete employee |
| `POST` | `/mcp/init` | Initialize database |

### Asset MCP

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/mcp/assets/allocate/{employeeId}` | Allocate asset to employee |
| `GET` | `/mcp/assets/employee/{employeeId}` | Get employee assets |
| `GET` | `/mcp/assets/inventory` | Get asset inventory |
| `POST` | `/mcp/assets/return/{assetId}` | Return asset |

## 🔧 Configuration

### Database Modes

The system supports three database modes:

- **`h2`** - Local H2 database (development)
- **`postgres`** - PostgreSQL database (production)
- **`mock`** - Mock responses (testing)

Set the mode in your `.env` file:
```
DB_MODE=postgres
```

### Environment Variables

Key configuration options in `.env`:

```bash
# Anypoint Platform
ANYPOINT_CLIENT_ID=your-client-id
ANYPOINT_CLIENT_SECRET=your-client-secret
ANYPOINT_ORG_ID=your-org-id
ANYPOINT_ENV=Sandbox

# Database
DB_MODE=postgres
POSTGRES_PASSWORD=secure_password

# Deployment
DEPLOYMENT_MODE=local  # or cloud
```

## 🐳 Docker Configuration

### Services

- All services run in isolated containers
- Shared PostgreSQL database
- Health checks and dependencies configured
- Persistent volume for database data

### Development Workflow

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Rebuild specific service
docker-compose build employee-mcp
docker-compose up -d employee-mcp
```

## ☁️ CloudHub Deployment

### Prerequisites

1. **Connected App Setup:**
   - Create Connected App in Anypoint Platform
   - Grant required permissions
   - Note Client ID and Client Secret

2. **Environment Setup:**
   - Ensure target environment exists
   - Configure deployment permissions

### Deployment Process

The `deploy-all.bat cloud` command:

1. Validates Anypoint CLI installation
2. Builds each MCP service with Maven
3. Deploys services in dependency order:
   - Employee MCP → Asset MCP → Agent Fabric
4. Provides CloudHub endpoints

## 🔍 Monitoring and Health Checks

### Health Endpoints

Each service provides health monitoring:

- `/agent/health` - Agent Fabric status + MCP service checks
- `/mcp/health` - Individual MCP service health
- Database connectivity validation
- Service dependency verification

### Logging

- Structured JSON logging
- Configurable log levels via `LOG_LEVEL` environment variable
- Centralized logging in CloudHub
- Docker container logs via `docker-compose logs`

## 🛠️ Development

### Project Structure

```
hr-onboarding-agent/
├── agent-fabric/           # Main orchestrator
│   ├── src/main/mule/     # Mule flows
│   ├── src/main/resources/ # Configuration
│   └── Dockerfile         # Container definition
├── employee-onboarding-mcp/ # Employee management
├── asset-allocation-mcp/   # Asset management
├── notification-mcp/       # Notifications (placeholder)
├── docker/                 # Docker configuration
│   ├── init-db.sql        # Database initialization
│   └── notification-mock/ # Mock notification service
├── docker-compose.yml     # Local orchestration
├── deploy-all.bat         # Deployment script
└── .env.example           # Configuration template
```

### Adding New MCP Services

1. Create new directory under project root
2. Add Mule application with standard structure
3. Create Dockerfile
4. Update docker-compose.yml
5. Add to deploy-all.bat script

### Database Schema Updates

- Update `docker/init-db.sql` for Docker deployment
- Update individual `*-init.sql` files in MCP services
- Restart services to apply changes

## 🔐 Security

### Authentication

- API key-based authentication between services
- Connected App authentication for CloudHub
- Environment-based credential management

### Best Practices

- Secrets stored in environment variables
- No credentials in source code
- Least privilege access principles
- Regular credential rotation

## 📝 Contributing

1. Fork the repository
2. Create feature branch
3. Update relevant documentation
4. Test locally with Docker
5. Submit pull request

## 🆘 Troubleshooting

### Common Issues

**Docker deployment fails:**
- Check Docker Desktop is running
- Verify port availability (8080-8083, 5432, 8090)
- Review docker-compose logs

**CloudHub deployment fails:**
- Verify Anypoint CLI configuration
- Check Connected App permissions
- Ensure environment exists and is accessible
- Review Maven build logs

**Database connectivity issues:**
- Check database mode in `.env`
- Verify PostgreSQL credentials
- Ensure database initialization completed
- Check network connectivity between services

### Support

For issues and questions:
1. Check logs with `docker-compose logs [service-name]`
2. Verify environment configuration
3. Review health check endpoints
4. Consult MuleSoft documentation for platform-specific issues

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
