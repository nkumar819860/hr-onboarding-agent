# Asset Allocation MCP Server

## Overview
The Asset Allocation MCP (Model Context Protocol) Server provides automated asset management capabilities for HR onboarding processes. This service manages the allocation, tracking, and lifecycle of company assets such as laptops, monitors, keyboards, and other equipment assigned to employees.

## Features
- **Asset Inventory Management**: Track available assets and their status
- **Automated Asset Allocation**: Assign assets to new employees during onboarding
- **Asset Lifecycle Tracking**: Monitor asset usage, maintenance, and retirement
- **Integration Ready**: MCP-compliant interface for seamless integration with HR systems

## API Endpoints
- `GET /assets` - List all available assets
- `POST /assets/{employeeId}/allocate` - Allocate assets to an employee
- `GET /assets/{employeeId}` - Get assets assigned to an employee
- `PUT /assets/{assetId}/status` - Update asset status
- `DELETE /assets/{employeeId}/{assetId}` - Deallocate asset from employee

## Asset Categories
- Laptops and computers
- Monitors and displays
- Input devices (keyboard, mouse)
- Communication equipment (headsets, phones)
- Office furniture (desk, chair)
- Security items (access cards, parking passes)

## Usage
This MCP server integrates with the HR Onboarding Agent Fabric to provide automated asset allocation as part of the employee onboarding workflow.
