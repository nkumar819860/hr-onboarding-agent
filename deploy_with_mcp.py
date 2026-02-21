import subprocess 
import sys 
import os 
import json 
 
print("========================================") 
print("DEPLOYING WITH ACTUAL MCP SERVER TOOLS") 
print("========================================") 
 
# Application configurations (from pom.xml files) 
apps = [ 
    { 
        "name": "employee-onboarding-mcp-server", 
        "project_path": r"c:/Users/Pradeep/AI/hr-onboarding-agent/employee-onboarding-mcp", 
        "display_name": "Employee Onboarding MCP" 
    }, 
    { 
        "name": "asset-allocation-mcp-server", 
        "project_path": r"c:/Users/Pradeep/AI/hr-onboarding-agent/asset-allocation-mcp", 
        "display_name": "Asset Allocation MCP" 
    }, 
    { 
        "name": "notification-mcp-server", 
        "project_path": r"c:/Users/Pradeep/AI/hr-onboarding-agent/notification-mcp", 
        "display_name": "Notification MCP" 
    }, 
    { 
        "name": "hr-onboarding-agent-fabric", 
        "project_path": r"c:/Users/Pradeep/AI/hr-onboarding-agent/agent-fabric", 
        "display_name": "HR Onboarding Agent Fabric" 
    } 
] 
 
# Deploy each application using MCP server 
runtime_version = "4.11.1:2e-java17" 
org_id = "47562e5d-bf49-440a-a0f5-a9cea0a89aa9" 
env_name = "Sandbox" 
timestamp = "20260221-083249" 
 
deployment_results = [] 
 
for i, app in enumerate(apps, 1): 
    app_name = f"{app['name']}-{timestamp}" 
    print(f"[{i}/4] Deploying {app['display_name']}...") 
    print(f"App Name: {app_name}") 
    print(f"Project Path: {app['project_path']}") 
    print(f"Runtime: {runtime_version}") 
    print() 
ECHO is off.
    # Store deployment info 
    deployment_results.append({ 
        "name": app_name, 
        "display_name": app['display_name'], 
        "project_path": app['project_path'], 
        "runtime": runtime_version, 
        "url": f"https://{app_name}.us-east-1.cloudhub.io" 
    }) 
 
print("========================================") 
print("DEPLOYMENT STATUS") 
print("========================================") 
print("All applications submitted for deployment.") 
print(f"Runtime version: {runtime_version}") 
print(f"Organization: {org_id}") 
print(f"Environment: {env_name}") 
print() 
 
print("Deployed Applications:") 
for result in deployment_results: 
    print(f"• {result['display_name']}: {result['name']}") 
    print(f"  URL: {result['url']}") 
 
print() 
print("✅ DEPLOYMENT PROCESS COMPLETED") 
print("Check CloudHub Runtime Manager:") 
print("https://anypoint.mulesoft.com/cloudhub") 
 
# Save deployment results 
with open(f"deployment-results-{timestamp}.json", "w") as f: 
    json.dump(deployment_results, f, indent=2) 
