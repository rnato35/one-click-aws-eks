# Deployment Guide

This guide covers the complete deployment process using manual deployment.

## Prerequisites

### 1. AWS Setup
- **AWS Account** with administrative permissions
- **S3 Bucket** for Terraform state storage
- **DynamoDB Table** for state locking
- **KMS Key** for state encryption
- **IAM Role** for GitHub OIDC authentication

### 2. Local Setup
- **Terraform** installed locally
- **kubectl** installed and configured
- **AWS CLI** configured with appropriate credentials
- **Helm** installed for application deployment

## Repository Setup

### Clone Repository
```bash
# Clone repository
git clone <your-repo>
cd one-click-aws-three-tier-foundation
```

## Deployment Process

### Phase 1: Infrastructure Deployment

#### 1. Configure Environment
```bash
git checkout env/dev
```

Edit `infra/envs/dev/terraform.tfvars`:
```hcl
env_name = "dev"
region   = "us-east-1"

# Networking
vpc_cidr = "10.0.0.0/16"
az_count = 2

# Features
enable_nat_gateway = true
single_nat_gateway = true
enable_flow_logs   = false
enable_nacls       = false

# EKS
enable_eks                              = true
eks_cluster_version                     = "1.33"
eks_enable_cluster_log_types            = ["api", "audit"]
eks_log_retention_in_days               = 7
eks_enable_aws_load_balancer_controller = true

# RBAC Configuration
eks_enable_rbac = true
eks_cluster_admin_arns = [
  "arn:aws:iam::YOUR_ACCOUNT_ID:user/YOUR_USERNAME"  # Replace with your IAM user ARN
]
eks_developer_arns = [
  # Add developer IAM user/role ARNs here
]
eks_viewer_arns = [
  # Add viewer IAM user/role ARNs here
]
eks_require_mfa = false  # Set to true for production
```

#### 2. Deploy Infrastructure
```bash
# Initialize Terraform
cd infra/envs
terraform init -backend-config="bucket=YOUR_BUCKET" -backend-config="region=YOUR_REGION" -backend-config="dynamodb_table=YOUR_TABLE"

# Create workspace for environment
terraform workspace new dev || terraform workspace select dev

# Plan deployment
terraform plan -var-file="dev/terraform.tfvars"

# Apply deployment
terraform apply -var-file="dev/terraform.tfvars"
```

**What happens:**
- Terraform deploys VPC, EKS cluster, networking
- Takes ~15-20 minutes for complete EKS cluster creation

#### 3. Verify Infrastructure
Check the Terraform outputs to ensure successful deployment.

#### 4. Configure Cluster Access
After successful deployment, configure access to the EKS cluster:

```bash
# Get your AWS account ID
aws sts get-caller-identity --query Account --output text

# Update kubeconfig for cluster access
aws eks update-kubeconfig --region us-east-1 --name one-click-dev-eks --profile YOUR_PROFILE

# Test cluster access
kubectl get nodes
kubectl get namespaces

# Check RBAC roles created (from Terraform outputs)
terraform output eks_rbac_roles
terraform output eks_rbac_authentication_guide
```

**Note**: If you encounter authentication issues, see the [EKS Authentication Guide](./EKS_AUTHENTICATION.md) and [Troubleshooting Guide](./TROUBLESHOOTING.md) for detailed instructions.

### Phase 2: Application Deployment

#### 1. Switch to Apps Branch
```bash
git checkout apps/dev
```

#### 2. Deploy Applications
```bash
# Navigate to applications directory
cd ../../modules/applications

# Initialize Terraform
terraform init -backend-config="bucket=YOUR_BUCKET" -backend-config="region=YOUR_REGION" -backend-config="dynamodb_table=YOUR_TABLE"

# Create workspace for environment
terraform workspace new dev || terraform workspace select dev

# Deploy applications
terraform apply -var="cluster_name=one-click-dev-eks" -var="region=us-east-1"
```

**What happens:**
- Terraform deploys Helm charts to EKS cluster
- Creates sample app in `apps` namespace
- Fixes CoreDNS issue by triggering Fargate node provisioning

#### 3. Verify Applications
```bash
# Configure kubectl
aws eks update-kubeconfig --name one-click-dev-eks --region us-east-1

# Check deployments
kubectl get all -n apps

# Check helm releases
helm list -A

# View application logs
kubectl logs -n apps -l app=observability-test
```

## Manual Deployment Workflow Examples

### Making Infrastructure Changes

#### Infrastructure Changes
```bash
# Make changes to configuration
# Edit infra/envs/dev/terraform.tfvars
# Change cluster settings, add new resources, etc.

# Plan changes
cd infra/envs
terraform workspace select dev
terraform plan -var-file="dev/terraform.tfvars"

# Apply changes
terraform apply -var-file="dev/terraform.tfvars"
```


### Making Application Changes

#### Update Application Configuration
```bash
# Update Helm values
# Edit modules/applications/values/dev/nginx-sample.yaml

# Plan changes
cd modules/applications
terraform workspace select dev
terraform plan -var="cluster_name=one-click-dev-eks" -var="region=us-east-1"

# Apply changes
terraform apply -var="cluster_name=one-click-dev-eks" -var="region=us-east-1"
```

#### Add New Application
```bash
# Create new Helm chart structure
mkdir -p modules/applications/charts/my-new-app

# Create values.yaml
cat > modules/applications/values/dev/my-new-app.yaml << EOF
replicaCount: 1
image:
  repository: nginx
  tag: latest
EOF

# Update applications Terraform
# Edit modules/applications/main.tf
# Add new helm_release resource

# Apply changes
cd modules/applications
terraform apply -var="cluster_name=one-click-dev-eks" -var="region=us-east-1"
```

## Environment Promotion

### Promote Infrastructure: Dev → Staging
```bash
# Copy dev configuration as base for staging
cp infra/envs/dev/terraform.tfvars infra/envs/staging/terraform.tfvars

# Update staging-specific configs
# Edit infra/envs/staging/terraform.tfvars
# Adjust for staging environment (larger resources, etc.)

# Deploy to staging
cd infra/envs
terraform workspace new staging || terraform workspace select staging
terraform plan -var-file="staging/terraform.tfvars"
terraform apply -var-file="staging/terraform.tfvars"
```

### Promote Applications: Dev → Staging
```bash
# Deploy applications to staging
cd modules/applications
terraform workspace new staging || terraform workspace select staging
terraform apply -var="cluster_name=one-click-staging-eks" -var="region=us-east-1"
```

## Emergency Deployments
For urgent fixes, deploy directly:
```bash
# Make urgent fix
# Edit configuration files as needed

# Deploy infrastructure fix
cd infra/envs
terraform workspace select <environment>
terraform apply -var-file="<environment>/terraform.tfvars"

# Deploy application fix
cd ../../modules/applications
terraform workspace select <environment>
terraform apply -var="cluster_name=one-click-<environment>-eks" -var="region=us-east-1"
```

## Troubleshooting

### Common Issues

#### 1. EKS Add-ons Already Exist
**Problem**: Error about existing add-ons
**Solution**: Add-ons are automatically managed by AWS, not Terraform

#### 2. CoreDNS Degraded Status  
**Problem**: CoreDNS shows "InsufficientNumberOfReplicas"
**Solution**: Deploy applications to trigger Fargate node provisioning

#### 3. Terraform State Lock
**Problem**: State file locked during concurrent runs
**Solution**: Wait for other operations to complete or break lock if needed

#### 4. GitHub OIDC Authentication Failed
**Problem**: Cannot assume AWS role
**Solution**: Verify IAM role trust policy and GitHub environment configuration

### Recovery Procedures

#### Reset Environment
```bash
# Destroy applications first
cd modules/applications
terraform workspace select <environment>
terraform destroy -var="cluster_name=one-click-<environment>-eks" -var="region=us-east-1"

# Destroy infrastructure
cd ../../infra/envs
terraform workspace select <environment>
terraform destroy -var-file="<environment>/terraform.tfvars"

# Redeploy as needed
```

#### Force Unlock State
```bash
# If needed (emergency only)
terraform force-unlock LOCK_ID
```

## Monitoring and Observability

### Access Applications
```bash
# Port forward to observability app
kubectl port-forward -n apps svc/observability-test 8080:80

# Access metrics
kubectl port-forward -n apps svc/observability-test 9113:9113
curl http://localhost:9113/metrics
```

### View Logs
```bash
# Application logs
kubectl logs -n apps -l app=observability-test

# EKS cluster logs (CloudWatch)
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/one-click-dev-eks"
```

### Check Resource Status
```bash
# Cluster info
kubectl cluster-info

# Node status
kubectl get nodes

# All resources
kubectl get all -A

# Helm releases
helm list -A
```