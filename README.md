# One-Click AWS Three-Tier Foundation

Complete Terraform solution for AWS three-tier architecture with EKS: VPC networking, EKS cluster with Fargate, AWS Load Balancer Controller, and application-ready namespaces.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS VPC                                      │
│                                 (10.0.0.0/16)                                  │
│                                                                                 │
│  ┌─────────────────────┐                      ┌─────────────────────┐         │
│  │   Public Tier       │                      │   Public Tier       │         │
│  │  (us-east-1a)       │                      │  (us-east-1b)       │         │
│  │ ┌─────────────────┐ │                      │ ┌─────────────────┐ │         │
│  │ │ Public Subnet   │ │                      │ │ Public Subnet   │ │         │
│  │ │ 10.0.0.0/20     │◄┼──────────────────────┼─┤ 10.0.16.0/20    │ │         │
│  │ └─────────────────┘ │                      │ └─────────────────┘ │         │
│  │         │           │                      │                     │         │
│  │    ┌────▼────┐      │                      │                     │         │
│  │    │ NAT GW  │      │                      │                     │         │
│  │    │ + EIP   │      │                      │                     │         │
│  │    └─────────┘      │                      │                     │         │
│  └─────────────────────┘                      └─────────────────────┘         │
│              │                                                                 │
│              │                  ┌─────────────────┐                           │
│              │                  │ Internet Gateway │                           │
│              │                  └─────────────────┘                           │
│              │                           │                                     │
│  ┌───────────▼─────────┐                │               ┌─────────────────────┐ │
│  │   Private App Tier  │◄───────────────┘               │   Private App Tier  │ │
│  │    (us-east-1a)     │                                │    (us-east-1b)     │ │
│  │ ┌─────────────────┐ │                                │ ┌─────────────────┐ │ │
│  │ │ Private Subnet  │ │     ┌─────────────────────┐    │ │ Private Subnet  │ │ │
│  │ │ 10.0.32.0/20    │ │     │                     │    │ │ 10.0.48.0/20    │ │ │
│  │ └─────────────────┘ │     │      EKS Cluster    │    │ └─────────────────┘ │ │
│  │                     │     │   (Control Plane)   │    │                     │ │
│  │ ┌─────────────────┐ │     │                     │    │ ┌─────────────────┐ │ │
│  │ │   EKS Fargate   │ │     │   ┌─────────────┐   │    │ │   EKS Fargate   │ │ │
│  │ │     Pods        │◄┼─────┼───┤ API Server  │   │    │ │     Pods        │ │ │
│  │ │                 │ │     │   └─────────────┘   │    │ │                 │ │ │
│  │ │ • default ns    │ │     │   ┌─────────────┐   │    │ │ • apps ns       │ │ │
│  │ │ • kube-system   │ │     │   │   etcd      │   │    │ │ • custom apps   │ │ │
│  │ │ • apps ns       │ │     │   └─────────────┘   │    │ │                 │ │ │
│  │ └─────────────────┘ │     └─────────────────────┘    │ └─────────────────┘ │ │
│  └─────────────────────┘                                └─────────────────────┘ │
│                                                                                 │
│  ┌─────────────────────┐                                ┌─────────────────────┐ │
│  │   Private DB Tier   │                                │   Private DB Tier   │ │
│  │    (us-east-1a)     │                                │    (us-east-1b)     │ │
│  │ ┌─────────────────┐ │                                │ ┌─────────────────┐ │ │
│  │ │ Private Subnet  │ │                                │ │ Private Subnet  │ │ │
│  │ │ 10.0.64.0/20    │ │        (No Internet Access)   │ │ 10.0.80.0/20    │ │ │
│  │ │                 │ │                                │ │                 │ │ │
│  │ │   (Reserved)    │ │                                │ │   (Reserved)    │ │ │
│  │ └─────────────────┘ │                                │ └─────────────────┘ │ │
│  └─────────────────────┘                                └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              EKS Components                                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐             │
│  │   Fargate       │    │   EKS Add-ons   │    │  Load Balancer  │             │
│  │   Profiles      │    │                 │    │   Controller    │             │
│  │                 │    │  • VPC CNI      │    │                 │             │
│  │ • default       │    │  • CoreDNS      │    │ • ALB/NLB       │             │
│  │ • kube-system   │    │  • kube-proxy   │    │ • Target Groups │             │
│  │ • apps          │    │                 │    │ • Security Grps │             │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘             │
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐             │
│  │   CloudWatch    │    │   IAM Roles     │    │   OIDC Provider │             │
│  │   Logging       │    │                 │    │                 │             │
│  │                 │    │ • EKS Cluster   │    │ • Service Acct  │             │
│  │ • API Server    │    │ • Fargate Exec  │    │   Authentication│             │
│  │ • Audit Logs    │    │ • LB Controller │    │                 │             │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Key Features

### **Networking**
- **3-Tier Architecture**: Public, Private App, Private DB subnets across 2 AZs
- **Internet Connectivity**: Internet Gateway for public access, NAT Gateway for private outbound
- **Automatic CIDR Calculation**: Auto-derives subnet CIDRs from VPC CIDR

### **EKS Cluster**
- **Fargate-Only**: Serverless container execution, no EC2 node management
- **Multi-Namespace**: Pre-configured namespaces (default, kube-system, apps)
- **AWS Load Balancer Controller**: Ready for ALB/NLB integration
- **Security**: KMS encryption, CloudWatch logging, OIDC for service accounts

### **Production-Ready**
- **High Availability**: Multi-AZ deployment
- **Monitoring**: CloudWatch integration for cluster and application logs
- **GitOps**: Branch-based deployment pipeline
- **Security**: Least-privilege IAM, network isolation

## Structure
- **modules/**
  - **network/**: VPC, subnets, routing, optional NACLs and flow logs
  - **eks/**: EKS cluster, Fargate profiles, add-ons, Load Balancer Controller
- **infra/envs/**: Root module with environment-specific configurations

## Quick Start

### Prerequisites
1. **AWS Account** with appropriate permissions
2. **S3 Bucket & DynamoDB Table** for Terraform backend
3. **GitHub OIDC** configured with AWS IAM role
4. **GitHub Environments** (dev, staging, prod) with secrets

### Option 1: GitOps Deployment (Recommended)

#### Step 1: Setup GitOps Branches
```bash
# Clone the repository
git clone <your-repo-url>
cd one-click-aws-three-tier-foundation

# Create infrastructure branches  
git checkout -b env/dev && git push -u origin env/dev
git checkout main && git checkout -b env/staging && git push -u origin env/staging
git checkout main && git checkout -b env/prod && git push -u origin env/prod

# Create application branches
git checkout main && git checkout -b apps/dev && git push -u origin apps/dev
git checkout main && git checkout -b apps/staging && git push -u origin apps/staging  
git checkout main && git checkout -b apps/prod && git push -u origin apps/prod
```

#### Step 2: Deploy Infrastructure
```bash
# Make infrastructure changes
git checkout env/dev
# Edit infra/envs/dev/terraform.tfvars with your settings
git add . && git commit -m "Configure dev environment"
git push origin env/dev
# GitHub Actions will automatically deploy infrastructure
```

#### Step 3: Deploy Applications
```bash
# Deploy applications
git checkout apps/dev
git add . && git commit -m "Deploy observability test app"
git push origin apps/dev  
# GitHub Actions will automatically deploy applications
```

### Option 2: Manual Deployment

#### Infrastructure
```bash
cd infra/envs
terraform init -backend-config="bucket=YOUR_BUCKET" # ... other backend configs
terraform apply -var-file="dev/terraform.tfvars"
```

#### Applications  
```bash
cd k8s/environments/dev
terraform init -backend-config="bucket=YOUR_BUCKET" # ... other backend configs
terraform apply -var="cluster_name=one-click-dev-eks"
```

### Option 3: Manual Triggers (GitHub UI)
1. Go to **GitHub Actions** tab
2. Select **terraform** or **applications** workflow
3. Click **"Run workflow"** 
4. Choose environment and action
5. Deploy with one click! 🚀

## Post-Deployment
After successful deployment:
```bash
# Configure kubectl
aws eks update-kubeconfig --name one-click-dev-eks --region us-east-1

# Check cluster status
kubectl get nodes
kubectl get pods -A

# Access observability test app
kubectl port-forward -n apps svc/observability-test 8080:80
curl http://localhost:8080

# View metrics
kubectl port-forward -n apps svc/observability-test 9113:9113  
curl http://localhost:9113/metrics
```

## GitOps Workflow

### Infrastructure Changes
1. **Create PR** against `env/dev` → Triggers terraform plan
2. **Merge PR** → Triggers terraform apply to dev
3. **Promote** to staging/prod by creating PRs against respective branches

### Application Changes  
1. **Create PR** against `apps/dev` → Triggers terraform plan
2. **Merge PR** → Triggers terraform apply to dev
3. **Promote** to staging/prod by creating PRs against respective branches

### Manual Deployments
- **Infrastructure**: Use **terraform** workflow with manual trigger
- **Applications**: Use **applications** workflow with manual trigger
- **Available for all environments**: dev, staging, prod
