# Azure DevOps Agents on Azure Kubernetes Services (AKS)

This repository contains all the necessary files and configurations to deploy Azure DevOps agents on Azure Kubernetes Services (AKS). The solution supports both Linux and Windows agents, with various specialized configurations for different types of workloads.

## Repository Structure

```
k8s-azure-devops-agents/
├── agents/              # Kubernetes manifests and configurations
├── image/              # Docker image configurations
│   ├── linux/          # Linux agent Docker configurations
│   ├── windows/        # Windows agent Docker configurations
│   └── resources/      # Shared resources
├── pipelines/          # Azure DevOps pipeline templates
└── util/              # Utility scripts
```

## Agent Types

The repository supports multiple agent types tailored for different workloads:

- `back`: Backend services agents
- `backws`: Backend services windows agents
- `data`: Data processing agents
- `dataws`: Data processing windows agents
- `front`: Frontend services agents
- `sre`: Site Reliability Engineering agents
- `vip`: VIP (specialized) agents

## Deployment Process

### Prerequisites

1. Azure Container Registry (ACR)
2. Kubernetes cluster
3. Azure DevOps organization and project
4. Service principal with appropriate permissions

### Build Process

The build process is automated through Azure DevOps pipelines and consists of:

1. Building Docker images for different agent types
2. Pushing images to Azure Container Registry
3. Tagging images with version and latest tags
4. Updating Kubernetes manifests with the new image tag

### Deployment

The deployment uses Kustomize for environment-specific configurations. The process involves:

1. Building the appropriate Docker image based on agent type
2. Pushing the image to Azure Container Registry
3. Updating Kubernetes manifests with the new image tag
4. Applying the configuration to the target Kubernetes cluster

## Usage

To deploy an agent:

1. Configure your Azure DevOps pipeline to use the `buildimage.yml` template
2. Specify the required parameters:
   - `serviceprincipal`: Azure service principal for ACR access
   - `registry`: Azure Container Registry name
   - `imagename`: Docker image name
   - `revision`: Image version
   - `platform`: Linux or Windows
   - `agentpool`: Type of agent (back, backws, data, etc.)
   - `environment`: Target environment (dev, staging, prod)

3. The pipeline will automatically:
   - Build the Docker image
   - Push it to ACR
   - Update Kubernetes manifests
   - Deploy to your cluster

## Customization

The repository includes customization options through:

- Different Dockerfile configurations for various agent types
- Environment-specific overlays using Kustomize
- Platform-specific configurations (Linux/Windows)
- Custom startup scripts ([start.sh](cci:7://file:///Users/jpezuela/Repos/k8s-azure-devops-agents/image/start.sh:0:0-0:0), [start.ps1](cci:7://file:///Users/jpezuela/Repos/k8s-azure-devops-agents/image/start.ps1:0:0-0:0))

## Security

The solution implements security best practices:

- Secure image builds using Azure Container Registry
- Environment-specific configurations
- Separation of concerns between Linux and Windows agents
- Secure startup scripts with proper permissions
