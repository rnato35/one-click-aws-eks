# Multi-Environment Terraform Deployment Guide

This repo supports manual multi-environment deployments for infrastructure and applications across three environments: dev, staging, prod.

## Environment Strategy

### Infrastructure Deployment
- **Environments**: dev, staging, prod
- **Configuration**: `infra/envs/{env}/terraform.tfvars`
- **Deployment**: Manual terraform commands with workspace isolation

### Application Deployment  
- **Environments**: dev, staging, prod
- **Configuration**: Environment-specific values in modules
- **Deployment**: Manual terraform/helm commands

## Deployment Process
- **Plan** changes using `terraform plan` for visibility
- **Apply** changes using `terraform apply` for deployment
- **Workspace isolation** for environment separation
- **Authentication** uses AWS CLI profiles or IAM roles

## Required Setup

1. **AWS Authentication**
   - Configure AWS CLI with appropriate credentials
   - Ensure IAM permissions for:
     - VPC, EKS, EC2 resources
     - S3 bucket access for state storage
     - DynamoDB table access for state locking
     - KMS key usage for encryption

2. **Backend Configuration**
   - S3 bucket for Terraform state storage
   - DynamoDB table for state locking
   - KMS key for state encryption
   - Update backend configuration in terraform init commands

3. **Local Tools**
   - Terraform installed and configured
   - kubectl installed for cluster access
   - Helm installed for application deployment
   - AWS CLI configured with proper profile

## Deployment Workflow

### Infrastructure Deployment
- **Plan**: Run `terraform plan -var-file="{env}/terraform.tfvars"` for infrastructure changes
- **Apply**: Run `terraform apply -var-file="{env}/terraform.tfvars"` for infrastructure deployment
- **Workspaces**: Use terraform workspaces for environment isolation

### Application Deployment  
- **Plan**: Run `terraform plan` with environment-specific variables
- **Apply**: Run `terraform apply` with environment-specific variables
- **Dependencies**: Requires EKS cluster to be deployed first
- **Helm**: Applications deployed via Terraform helm provider

### State File Organization
- **Infrastructure**: `global/terraform.tfstate` (with workspaces)
- **Applications**: `k8s/{environment}/terraform.tfstate` (separate states per environment)

## Local Usage

### Infrastructure Deployment
```bash
cd infra/envs
terraform init -backend-config="bucket=YOUR_BUCKET" -backend-config="region=YOUR_REGION" -backend-config="dynamodb_table=YOUR_TABLE"
terraform workspace new dev || terraform workspace select dev
terraform plan -var-file="dev/terraform.tfvars"
terraform apply -var-file="dev/terraform.tfvars"
```

### Application Deployment
```bash
cd modules/applications
terraform init -backend-config="bucket=YOUR_BUCKET" -backend-config="region=YOUR_REGION" -backend-config="dynamodb_table=YOUR_TABLE"
terraform workspace new dev || terraform workspace select dev
terraform apply -var="cluster_name=one-click-dev-eks" -var="region=us-east-1"
```

## Notes

- Store backend configuration securely and do not commit to version control
- Use workspace isolation to manage multiple environments
- Ensure proper IAM permissions for all AWS resources being created
