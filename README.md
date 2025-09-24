# One-Click AWS EKS Fargate Solution

Complete Terraform solution for production-ready AWS EKS Fargate deployment. Includes VPC networking, EKS cluster with Fargate profiles, AWS Load Balancer Controller, comprehensive RBAC, and **sample nginx application deployed automatically**.

🚀 **One-click deployment** - Single `terraform apply` command deploys complete infrastructure AND applications with working load balancer endpoint!

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS VPC                                      │
│                                 (10.0.0.0/16)                                  │
│                                                                                 │
│  ┌─────────────────────┐                      ┌─────────────────────┐         │
│  │   Public Subnets    │                      │   Public Subnets    │         │
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
│  │   Private Subnets   │◄───────────────┘               │   Private Subnets   │ │
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

- **2-Tier Architecture**: Public and Private subnets across 2 AZs
- **Internet Connectivity**: Internet Gateway for public access, NAT Gateway for private outbound
- **Automatic CIDR Calculation**: Auto-derives subnet CIDRs from VPC CIDR

### **EKS Cluster**

- **Fargate-Only**: Serverless container execution, no EC2 node management
- **Multi-Namespace**: Pre-configured namespaces (default, kube-system, apps)
- **AWS Load Balancer Controller**: Ready for ALB/NLB integration
- **Security**: KMS encryption, CloudWatch logging, OIDC for service accounts
- **RBAC**: Tiered access control with dedicated IAM roles and Kubernetes RBAC

### **Production-Ready**

- **High Availability**: Multi-AZ deployment
- **Monitoring**: CloudWatch integration for cluster and application logs
- **Security**: Least-privilege IAM, network isolation, comprehensive RBAC

### **Access Control & Security**

- **🔴 Cluster Admins**: Platform team with full cluster access
- **🟡 Developers**: Namespace-scoped access for application development
- **🟢 Viewers**: Read-only access for monitoring and troubleshooting
- **MFA Support**: Optional multi-factor authentication for role assumption

## Structure

```
one-click-aws-eks/
├── infra/
│   └── envs/              # Root module with environment configurations (dev/staging/prod)
│       ├── dev/           # Development environment tfvars
│       ├── staging/       # Staging environment tfvars
│       └── prod/          # Production environment tfvars
├── modules/
│   ├── network/           # VPC, subnets, routing, NAT gateway, security groups
│   ├── eks/              # EKS cluster, Fargate profiles, RBAC, Load Balancer Controller
│   └── applications/     # Helm charts for nginx sample application
└── scripts/              # Cleanup and utility scripts
```

## Quick Start

### Prerequisites

1. **AWS Account** with appropriate EKS permissions
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.6.0 installed
4. **kubectl** installed (for post-deployment verification)

### Deployment

```bash
# Clone the repository
git clone https://github.com/rnato35/one-click-aws-eks.git
cd one-click-aws-eks

# Navigate to infrastructure directory
cd infra/envs

# Configure your environment (edit dev/terraform.tfvars with your settings)
# Modify variables like region, domain_name, certificate_arn, etc.

# Initialize Terraform
terraform init

# Optional: Configure remote backend
# terraform init -backend-config="bucket=YOUR_BUCKET" -backend-config="key=eks-dev/terraform.tfstate" -backend-config="region=us-east-1"

# Deploy everything with one command
terraform apply -var-file="dev/terraform.tfvars"
```


## Post-Deployment

### Cluster Access Setup

After successful deployment, configure cluster access using the RBAC system:

```bash
# 1. Get cluster information from Terraform outputs
terraform output eks_rbac_roles
terraform output eks_rbac_authentication_guide

# 2. Configure kubectl with admin access (if you're in cluster_admin_arns)
aws eks update-kubeconfig --name one-click-dev-eks --region us-east-1 --profile YOUR_PROFILE

# 3. Test cluster access
kubectl get nodes
kubectl get namespaces

# 4. Check RBAC configuration
kubectl get clusterrolebindings | grep eks
kubectl get rolebindings -n apps
```

### Role-Based Access Examples

```bash
# For Developers (namespace-scoped access)
# First assume the developer role, then:
kubectl get pods -n apps              # ✅ Allowed
kubectl create deployment -n apps     # ✅ Allowed  
kubectl get nodes                     # ✅ Allowed (read-only)
kubectl delete namespace kube-system  # ❌ Forbidden

# For Viewers (read-only access)
# First assume the viewer role, then:
kubectl get pods -A                   # ✅ Allowed
kubectl describe deployment -n apps   # ✅ Allowed
kubectl create deployment -n apps     # ❌ Forbidden

```

### Application Testing

After deployment, test the nginx sample application:

**Option 1: If you configured a custom domain and certificate:**
```bash
# Get ingress details
kubectl get ingress -n apps

# Test your website
curl https://your-domain.com/
curl https://your-domain.com/health
```

**Option 2: Using port forwarding (for local testing):**
```bash
# Port forward to the nginx service
kubectl port-forward -n apps svc/nginx-sample 8080:80

# Test locally
curl http://localhost:8080/
curl http://localhost:8080/health
```

**Additional verification:**
```bash
# Check all application resources
kubectl get all -n apps

# View application logs
kubectl logs -n apps deployment/nginx-sample
```

## What Gets Deployed

This single Terraform configuration automatically deploys:

### 🌐 **Networking Infrastructure**
- VPC with public/private subnets across 2 availability zones
- Internet Gateway and single NAT Gateway (cost-optimized)
- Route tables and security groups with least-privilege rules
- Optional VPC Flow Logs and Network ACLs

### 🚀 **EKS Cluster**
- Managed EKS control plane with Fargate execution
- Fargate profiles for `default`, `kube-system`, and `apps` namespaces
- AWS Load Balancer Controller for native ALB/NLB integration
- EKS add-ons: VPC CNI, CoreDNS, kube-proxy
- CloudWatch logging for API server and audit logs
- OIDC provider for service account authentication

### 🔒 **Security & RBAC**
- IAM groups for tiered access control:
  - **eks-devops**: Full cluster administration
  - **eks-developers**: Namespace-scoped access with read/write in apps
  - **eks-viewers**: Read-only cluster access
- Service accounts and IAM roles for secure pod-level permissions
- Network isolation and encryption at rest

### 📦 **Sample Application**
- Nginx web server with custom HTML content
- Kubernetes deployment, service, and ingress resources
- Health check endpoints for monitoring
- Optional public ALB with custom domain/SSL certificate
- Horizontal Pod Autoscaler configuration ready

## Environment Management

The project supports multiple environments with isolated configurations:

- **Development** (`dev/`): Full features enabled, single NAT gateway
- **Staging** (`staging/`): Production-like setup for testing
- **Production** (`prod/`): High availability, MFA required, enhanced logging

Each environment uses separate:
- Terraform tfvars files
- AWS resource naming (cluster names, IAM roles)
- Kubernetes namespaces and RBAC policies
- Optional Terraform workspace isolation

## Cost Optimization

- **Fargate**: Pay-per-pod pricing, no idle EC2 instances
- **Resource Limits**: Prevent container resource waste
- **Configurable Features**: Enable only what you need (flow logs, NACLs, etc.)
