# Kubernetes Deployments

This directory contains Kubernetes and Helm deployments organized by environment and application.

## Directory Structure

```
k8s/
├── apps/                           # Application-specific configurations
│   └── observability-test/        # Observability test application
│       └── values.yaml            # Base Helm values
├── environments/                   # Environment-specific deployments
│   └── dev/                       # Development environment
│       ├── main.tf                # Terraform configuration
│       ├── variables.tf           # Input variables
│       ├── outputs.tf             # Output values
│       └── values.yaml            # Environment-specific overrides
└── README.md                      # This file
```

## Usage

### Prerequisites

1. **EKS Cluster**: Ensure the EKS cluster is deployed via the infrastructure modules
2. **AWS CLI**: Configured with appropriate credentials
3. **kubectl**: Configured to access the EKS cluster
4. **Terraform**: Version >= 1.6.0

### Deploying Applications

#### Step 1: Deploy Infrastructure
First, deploy the EKS cluster and networking infrastructure:

```bash
cd infra/envs
terraform init
terraform apply -var-file="dev/terraform.tfvars"
```

#### Step 2: Configure kubectl
Configure kubectl to access the EKS cluster:

```bash
aws eks update-kubeconfig --name one-click-dev-eks --region us-east-1
```

#### Step 3: Deploy Applications
Deploy applications to the cluster:

```bash
cd k8s/environments/dev
terraform init
terraform apply -var="cluster_name=one-click-dev-eks"
```

### Environment Structure

Each environment directory (`dev/`, `staging/`, `prod/`) contains:

- **`main.tf`**: Terraform configuration with Helm releases
- **`variables.tf`**: Environment-specific variables
- **`outputs.tf`**: Outputs for deployed resources
- **`values.yaml`**: Environment-specific Helm value overrides

### Application Structure

Each application directory (`apps/app-name/`) contains:

- **`values.yaml`**: Base Helm values that work across all environments
- **Additional files**: Charts, templates, or configuration files as needed

## Best Practices

### 1. Value Inheritance
- **Base values**: Defined in `apps/app-name/values.yaml`
- **Environment overrides**: Defined in `environments/env/values.yaml`
- **Terraform sets**: Used for dynamic values (cluster name, region, etc.)

### 2. Environment Isolation
- Each environment has its own Terraform state
- Applications are deployed independently per environment
- Shared configurations are kept in the apps directory

### 3. Observability
The observability-test application includes:
- **Prometheus metrics**: Exposed on port 9113
- **Health checks**: Liveness and readiness probes
- **Resource limits**: CPU and memory constraints
- **Pod annotations**: For monitoring and logging

### 4. Security
- **Non-root containers**: Security contexts enforce non-root execution
- **Resource limits**: Prevent resource exhaustion
- **Network policies**: (Optional) Control network traffic
- **Service accounts**: Dedicated service accounts for applications

## Customization

### Adding New Applications

1. **Create app directory**:
   ```bash
   mkdir -p k8s/apps/my-new-app
   ```

2. **Create base values**:
   ```yaml
   # k8s/apps/my-new-app/values.yaml
   replicaCount: 1
   image:
     repository: my-app
     tag: latest
   ```

3. **Add to environment**:
   ```hcl
   # k8s/environments/dev/main.tf
   resource "helm_release" "my_new_app" {
     name  = "my-new-app"
     chart = "my-chart"
     
     values = [
       file("${path.module}/../../apps/my-new-app/values.yaml"),
       file("${path.module}/my-new-app-values.yaml")
     ]
   }
   ```

### Environment-Specific Overrides

Create environment-specific value files:

```yaml
# k8s/environments/dev/my-app-values.yaml
replicaCount: 1
resources:
  requests:
    memory: 128Mi
    cpu: 100m

# k8s/environments/prod/my-app-values.yaml
replicaCount: 3
resources:
  requests:
    memory: 512Mi
    cpu: 500m
```

## Monitoring and Observability

The deployed applications include:

- **Metrics**: Prometheus-compatible metrics endpoints
- **Logging**: Structured logging with environment context
- **Health checks**: Kubernetes liveness and readiness probes
- **Resource monitoring**: CPU and memory usage tracking

Access the observability test application:

```bash
# Port forward to access the application
kubectl port-forward -n apps svc/observability-test 8080:80

# Access metrics
kubectl port-forward -n apps svc/observability-test 9113:9113
curl http://localhost:9113/metrics
```