# Deployment Guide

This guide covers the complete deployment process using GitOps methodology.

## Prerequisites

### 1. AWS Setup
- **AWS Account** with administrative permissions
- **S3 Bucket** for Terraform state storage
- **DynamoDB Table** for state locking
- **KMS Key** for state encryption
- **IAM Role** for GitHub OIDC authentication

### 2. GitHub Setup
- **Repository** with this code
- **GitHub Environments**: dev, staging, prod
- **Secrets** configured in each environment:
  - `AWS_ROLE_ARN`: IAM role ARN for OIDC
- **Variables** configured at repository level:
  - `TF_BACKEND_BUCKET`: S3 bucket name
  - `TF_BACKEND_REGION`: AWS region
  - `TF_BACKEND_DDB_TABLE`: DynamoDB table name
  - `TF_BACKEND_KMS_KEY_ID`: KMS key ID/ARN

## GitOps Branch Setup

### Initial Branch Creation
```bash
# Clone repository
git clone <your-repo>
cd one-click-aws-three-tier-foundation

# Create infrastructure branches
git checkout -b env/dev
git push -u origin env/dev

git checkout main
git checkout -b env/staging
git push -u origin env/staging

git checkout main
git checkout -b env/prod
git push -u origin env/prod

# Create application branches
git checkout main
git checkout -b apps/dev
git push -u origin apps/dev

git checkout main
git checkout -b apps/staging
git push -u origin apps/staging

git checkout main
git checkout -b apps/prod
git push -u origin apps/prod
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
eks_cluster_version                     = "1.30"
eks_enable_cluster_log_types            = ["api", "audit"]
eks_log_retention_in_days               = 7
eks_enable_aws_load_balancer_controller = true
```

#### 2. Deploy Infrastructure
```bash
git add .
git commit -m "Configure dev environment infrastructure"
git push origin env/dev
```

**What happens:**
- GitHub Actions triggers `terraform.yaml` workflow
- Terraform deploys VPC, EKS cluster, networking
- Takes ~15-20 minutes for complete EKS cluster creation

#### 3. Verify Infrastructure
Monitor the GitHub Actions workflow to ensure successful deployment.

### Phase 2: Application Deployment

#### 1. Switch to Apps Branch
```bash
git checkout apps/dev
```

#### 2. Deploy Applications
```bash
git add .
git commit -m "Deploy observability test application"
git push origin apps/dev
```

**What happens:**
- GitHub Actions triggers `applications.yaml` workflow
- Terraform deploys Helm charts to EKS cluster
- Creates observability test app in `apps` namespace
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

## GitOps Workflow Examples

### Making Infrastructure Changes

#### Option 1: Pull Request Workflow
```bash
# Create feature branch from env/dev
git checkout env/dev
git pull origin env/dev
git checkout -b feature/increase-cluster-size

# Make changes
# Edit infra/envs/dev/terraform.tfvars
# Change cluster settings, add new resources, etc.

# Commit and push
git add .
git commit -m "Increase EKS cluster resources"
git push origin feature/increase-cluster-size

# Create PR against env/dev
# GitHub will automatically run terraform plan
# Review plan output in PR comments
# Merge PR to trigger terraform apply
```

#### Option 2: Direct Push (Dev Only)
```bash
git checkout env/dev
# Make changes directly
git add .
git commit -m "Update dev configuration"
git push origin env/dev
# Triggers immediate deployment
```

### Making Application Changes

#### Update Application Configuration
```bash
# Create feature branch
git checkout apps/dev
git pull origin apps/dev
git checkout -b feature/update-app-config

# Update Helm values
# Edit k8s/environments/dev/values.yaml
# Edit k8s/apps/observability-test/values.yaml

# Commit and push
git add .
git commit -m "Update observability app configuration"
git push origin feature/update-app-config

# Create PR against apps/dev
# Review plan output
# Merge to deploy
```

#### Add New Application
```bash
# Create new app structure
mkdir -p k8s/apps/my-new-app

# Create values.yaml
cat > k8s/apps/my-new-app/values.yaml << EOF
replicaCount: 1
image:
  repository: nginx
  tag: latest
EOF

# Update environment Terraform
# Edit k8s/environments/dev/main.tf
# Add new helm_release resource

# Commit and deploy
git add .
git commit -m "Add new application"
git push origin apps/dev
```

## Environment Promotion

### Promote Infrastructure: Dev → Staging
```bash
# Create PR from env/dev to env/staging
git checkout env/staging
git pull origin env/staging
git checkout -b promote/dev-to-staging

# Merge dev changes
git merge env/dev

# Update staging-specific configs
# Edit infra/envs/staging/terraform.tfvars
# Adjust for staging environment (larger resources, etc.)

# Commit and create PR
git add .
git commit -m "Promote dev changes to staging"
git push origin promote/dev-to-staging

# Create PR against env/staging
# Review and merge
```

### Promote Applications: Dev → Staging
```bash
# Similar process for applications
git checkout apps/staging
git pull origin apps/staging
git checkout -b promote/apps-dev-to-staging

git merge apps/dev

# Update staging values
# Edit k8s/environments/staging/values.yaml

git add .
git commit -m "Promote applications to staging"
git push origin promote/apps-dev-to-staging

# Create PR and merge
```

## Manual Deployments

### Using GitHub Actions UI
1. Go to **GitHub Actions** tab
2. Select workflow:
   - **terraform** for infrastructure
   - **applications** for apps
3. Click **"Run workflow"**
4. Select:
   - **Environment**: dev/staging/prod
   - **Action**: plan/apply
5. Click **"Run workflow"**

### Emergency Deployments
For urgent fixes, use manual triggers:
```bash
# Make urgent fix on main branch
git checkout main
# Make fix
git add . && git commit -m "Urgent fix"
git push origin main

# Deploy via GitHub Actions manual trigger
# Select environment and apply
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
# Use destroy workflow (manual trigger)
# Select environment and confirm destruction
# Redeploy infrastructure and applications
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