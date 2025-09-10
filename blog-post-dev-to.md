Welcome to my **One-Click AWS Deployments** post. This is a complete guide to deploying a three-tier architecture with EKS using Terraform.

In this post, you'll deploy a **complete three-tier architecture with EKS using Terraform**. No more spending hours setting up VPCs, subnets, EKS clusters, load balancers, and applications separately. We use **Terraform modules + Helm** to provision everything from network infrastructure to a running nginx website automatically.

---

## What You Get

A single `terraform apply` command creates:

- **Complete networking stack** across 2 AZs
  - VPC with public, private app, and private DB subnets
  - Internet Gateway, NAT Gateway with EIP
  - Security groups with least-privilege access
- **Production-ready EKS cluster**
  - Fargate-only execution (no EC2 node management)
  - AWS Load Balancer Controller for native ALB integration
  - Multi-tier RBAC with IAM Groups and roles
- **Sample nginx website deployed automatically**
  - Custom HTML showing the architecture diagram
  - Health check endpoint (`/health`)
  - Application Load Balancer with public access
- **Multi-environment support** for dev, staging, prod

---

## Why This Matters

Setting up a three-tier architecture with EKS is usually a multi-day process:

1. Create and configure VPC with proper subnets
2. Set up NAT gateways and route tables
3. Provision EKS cluster with Fargate profiles
4. Install and configure AWS Load Balancer Controller
5. Set up RBAC and IAM role integration
6. Deploy applications with proper ingress
7. Configure health checks and monitoring
8. Wire everything together

This template does it **all in one command** and gives you a working website with a load balancer endpoint, following AWS best practices for security and high availability.

---

## Repository Structure
```plaintext
one-click-aws-three-tier-eks/
├── infra/
│   └── envs/           # Root stack with environment configs
├── modules/
│   ├── network/        # VPC, subnets, NAT, security groups
│   ├── eks/           # EKS cluster, Fargate, Load Balancer Controller
│   └── applications/  # Helm chart for nginx sample app
└── docs/           # Documentation and guides
```

---

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
│  │ │ Public Subnet   │ │  ┌─────────────────┐ │ │ Public Subnet   │ │         │
│  │ │ 10.0.0.0/20     │◄┼──┤ Internet Gateway ├─┤ 10.0.16.0/20    │ │         │
│  │ └─────────────────┘ │  └─────────────────┘ │ └─────────────────┘ │         │
│  │         │           │                      │                     │         │
│  │    ┌────▼────┐      │                      │                     │         │
│  │    │ ALB     │      │                      │                     │         │
│  │    │(nginx)  │      │                      │                     │         │
│  │    └─────────┘      │                      │                     │         │
│  └─────────────────────┘                      └─────────────────────┘         │
│              │                                                                 │
│  ┌───────────▼─────────┐                               ┌─────────────────────┐ │
│  │   Private App Tier  │                               │   Private App Tier  │ │
│  │    (us-east-1a)     │                               │    (us-east-1b)     │ │
│  │ ┌─────────────────┐ │     ┌─────────────────────┐   │ ┌─────────────────┐ │ │
│  │ │ Private Subnet  │ │     │                     │   │ │ Private Subnet  │ │ │
│  │ │ 10.0.32.0/20    │ │     │      EKS Cluster    │   │ │ 10.0.48.0/20    │ │ │
│  │ └─────────────────┘ │     │   (Control Plane)   │   │ └─────────────────┘ │ │
│  │                     │     │                     │   │                     │ │
│  │ ┌─────────────────┐ │     │   ┌─────────────┐   │   │ ┌─────────────────┐ │ │
│  │ │   EKS Fargate   │◄┼─────┼───┤ API Server  │   │   │ │   EKS Fargate   │ │ │
│  │ │     Pods        │ │     │   └─────────────┘   │   │ │     Pods        │ │ │
│  │ │                 │ │     └─────────────────────┘   │ │                 │ │ │
│  │ │ • nginx-sample  │ │                               │ │ • apps namespace│ │ │
│  │ │ • /architecture │ │                               │ │ • ready for     │ │ │
│  │ │ • /health       │ │                               │ │   more apps     │ │ │
│  │ └─────────────────┘ │                               │ └─────────────────┘ │ │
│  └─────────────────────┘                               └─────────────────────┘ │
│                                                                                 │
│  ┌─────────────────────┐                               ┌─────────────────────┐ │
│  │   Private DB Tier   │                               │   Private DB Tier   │ │
│  │    (us-east-1a)     │                               │    (us-east-1b)     │ │
│  │ ┌─────────────────┐ │                               │ ┌─────────────────┐ │ │
│  │ │ Private Subnet  │ │        (Ready for RDS,        │ │ Private Subnet  │ │ │
│  │ │ 10.0.64.0/20    │ │         ElastiCache)         │ │ 10.0.80.0/20    │ │ │
│  │ └─────────────────┘ │                               │ └─────────────────┘ │ │
│  └─────────────────────┘                               └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

**Required setup:**
- AWS account with EKS permissions
- Terraform installed locally
- kubectl installed locally (for post-deployment testing)
- AWS CLI configured with appropriate credentials
- Terraform backend with S3 + DynamoDB (optional but recommended)

---

## Manual Deployment

### 1. Clone and setup

```bash
git clone <your-repo-url>
cd one-click-aws-three-tier-eks
```

### 2. Configure your environment

```bash
# Edit dev configuration
# Modify infra/envs/dev/terraform.tfvars with your settings:
# - region = "us-east-1"
# - nginx_sample_domain_name = "your-domain.com"  
# - nginx_sample_certificate_arn = "your-acm-cert-arn"
```

### 3. Deploy with Terraform

```bash
# Navigate to infrastructure directory
cd infra/envs

# Initialize Terraform
terraform init

# Create workspace for environment isolation
terraform workspace new dev

# Plan the deployment
terraform plan -var-file="dev/terraform.tfvars"

# Deploy everything
terraform apply -var-file="dev/terraform.tfvars"
```

Terraform automatically runs the unified deployment:
- **Infrastructure phase**: Complete networking, EKS cluster, Load Balancer Controller
- **Applications phase**: nginx sample app with ingress and load balancer
- **All in one configuration**: No need to manage separate deployments

---

## What Gets Deployed in Detail

### Networking Infrastructure
- **VPC**: 10.0.0.0/16 with DNS support across 2 AZs
- **Public subnets**: For load balancers (10.0.0.0/20, 10.0.16.0/20)
- **Private app subnets**: For EKS workloads (10.0.32.0/20, 10.0.48.0/20)
- **Private DB subnets**: Ready for databases (10.0.64.0/20, 10.0.80.0/20)
- **Single NAT Gateway**: Cost-optimized outbound internet access
- **Security Groups**: Least-privilege firewall rules

### EKS Cluster Components
- **Managed control plane**: High availability across multiple AZs
- **Fargate profiles**: For default, kube-system, and apps namespaces
- **OIDC provider**: For Kubernetes service account authentication
- **Cluster add-ons**: VPC CNI, CoreDNS, kube-proxy
- **AWS Load Balancer Controller**: Native integration with ALB/NLB
- **CloudWatch logging**: API server and audit logs

### Security & RBAC
- **IAM Groups-based access control**: 
  - 🔴 **{cluster-name}-eks-devops**: Full cluster admin access
  - 🟡 **{cluster-name}-eks-developers**: Read/Write in apps namespace, read-only elsewhere
  - 🟢 **{cluster-name}-eks-viewers**: Read-only cluster access
- **Assumable IAM roles**: Users in groups can assume roles for cluster access
- **Service accounts**: For pod-level AWS permissions
- **Network isolation**: Private subnets with no direct internet access

### Sample Nginx Application
- **Custom HTML content**: Shows the architecture diagram on the website at `/architecture`
- **Health endpoint**: `/health` for application monitoring and ALB health checks
- **Application Load Balancer**: Internet-facing with health checks
- **Kubernetes resources**:
  - Deployment with configurable replicas
  - Service for internal load balancing
  - Ingress for external access
  - ConfigMaps for HTML and nginx configuration

---

## Post-Deployment: Access Your Website & Cluster

### 1. Set up cluster access (for admins)

Add your IAM user to the appropriate IAM Group, then:

```bash
# Assume the cluster admin role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT:role/one-click-dev-eks-cluster-admins \
  --role-session-name admin-session

# Export the temporary credentials, then configure kubectl
aws eks update-kubeconfig --name one-click-dev-eks --region us-east-1

# Verify cluster access
kubectl get nodes
kubectl get namespaces
kubectl get pods -n apps
```

### 2. Access your website

There are **two options** to visualize the nginx sample application:

**Option 1: Public ALB with Custom Domain (Production-ready)**
1. Configure a certificate and put its ARN in the `nginx_sample_certificate_arn` variable
2. Set your custom domain in the `nginx_sample_domain_name` variable
3. Access via your custom domain over HTTPS

**Option 2: Local Port Forwarding (Development/Testing)**
1. Don't define the certificate and domain variables
2. Use kubectl port forwarding to access the service locally:

```bash
# Forward local port to the nginx service
kubectl port-forward -n apps service/nginx-sample 8080:80

# Visit your website locally
curl http://localhost:8080/architecture
curl http://localhost:8080/health
```

**For Option 1 (Public ALB):**
```bash
# Get the load balancer URL
kubectl get ingress -n apps

# Visit your website
curl http://<your-alb-dns-name>/architecture

# Test health endpoint
curl http://<your-alb-dns-name>/health
```

### 3. Test RBAC with different roles

```bash
# For developers (namespace-scoped access)
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT:role/one-click-dev-eks-developers \
  --role-session-name dev-session

# Test permissions
kubectl get pods -n apps              # ✅ Allowed  
kubectl get nodes                     # ✅ Allowed (read-only)
kubectl delete namespace kube-system  # ❌ Forbidden
```

---

## Deployment Process Explained

### Unified Deployment Process
This project uses **a single Terraform configuration** that handles everything:

1. **Infrastructure deployment**
   - VPC, subnets, EKS cluster, load balancer controller
   - All networking components and security groups
   
2. **Applications deployment**
   - nginx sample app and all Kubernetes resources
   - Deployed automatically after infrastructure is ready

### Environment Management
- **Terraform workspaces**: Isolate state for different environments
- **Separate tfvars files**: Environment-specific configurations
- **Sequential deployment**: Infrastructure first, then applications automatically

### Environment Isolation
Each environment uses:
- Separate tfvars files (`dev/`, `staging/`, `prod/`)
- Different cluster names and configurations
- Isolated AWS resources and namespaces
- Terraform workspace isolation

### IAM Groups Integration
- **Automatic creation**: IAM Groups are created for each cluster
- **User management**: Add IAM users to groups for appropriate access
- **Role assumption**: Users assume roles based on group membership
- **MFA support**: Optional MFA requirements for role assumption

---

## Advanced Features

### Cost Optimization
- **Single NAT Gateway**: ~50% cost reduction vs. multi-AZ NAT
- **Fargate pricing**: Pay-per-pod, no idle EC2 instances
- **Resource limits**: Prevent resource waste in containers

### Production Readiness  
- **Multi-AZ deployment**: High availability by default
- **Health checks**: Application-aware load balancer probes
- **Auto scaling**: Horizontal Pod Autoscaler ready
- **Monitoring**: CloudWatch integration ready for extension

### Extensibility
- **Database-ready**: Private DB subnets for RDS/ElastiCache
- **Modular design**: Add applications via additional Helm charts
- **RBAC foundation**: Easy to add users to IAM Groups
- **Monitoring ready**: Foundation for Prometheus, Grafana, ELK stack

---

## Call to Action

Deploy your own three-tier architecture with **one command**:
[GitHub Repository](https://github.com/rnato35/one-click-aws-three-tier-eks)

This gives you a complete, production-ready AWS foundation with automated infrastructure provisioning and application deployment through Terraform.

---

*What would you like to see deployed with one click next? Drop a comment below!*