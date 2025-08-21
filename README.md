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
1. Configure backend (S3/DynamoDB) in `infra/envs/versions.tf`
2. Set variables in `infra/envs/dev/terraform.tfvars`
3. Deploy: `cd infra/envs && terraform init && terraform apply`

## Post-Deployment
After successful deployment:
- Configure `kubectl` with: `aws eks update-kubeconfig --name one-click-dev-eks`
- Install AWS Load Balancer Controller via Helm
- Deploy applications to the `apps` namespace
