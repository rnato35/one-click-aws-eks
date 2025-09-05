# Architecture Overview - One-Click AWS Three-Tier Foundation

## 🏗️ Complete Architecture

This project implements a production-ready, cloud-native three-tier architecture on AWS with true one-click deployment.

### 📊 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                           Internet Users                             │
└─────────────────────────┬────────────────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────────────┐
│                      Presentation Tier                               │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │              AWS Application Load Balancer                      │ │
│  │                    (Public Subnets)                             │ │
│  │  • SSL/TLS Termination  • Health Checks  • Auto Scaling        │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────┬────────────────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────────────┐
│                      Application Tier                                │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                    Amazon EKS Cluster                           │ │
│  │                   (Private App Subnets)                        │ │
│  │                                                                 │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐         │ │
│  │  │nginx-sample │  │observability│  │   Future Apps   │         │ │
│  │  │   Fargate   │  │    test     │  │   (microservices│         │ │
│  │  │    Pods     │  │   Fargate   │  │    APIs, etc.)  │         │ │
│  │  │             │  │    Pods     │  │                 │         │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘         │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────┬────────────────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────────────┐
│                         Data Tier                                    │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                 Private Database Subnets                        │ │
│  │              (Ready for RDS, ElastiCache)                      │ │
│  │                                                                 │ │
│  │  • Network isolated  • Multi-AZ ready  • Encrypted storage     │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

## 🏢 Infrastructure Components

### 1. **Networking Layer** (`modules/network/`)
- **VPC**: 10.0.0.0/16 with DNS support
- **Public Subnets**: 2 AZs for load balancers (10.0.0.0/20, 10.0.16.0/20)
- **Private App Subnets**: 2 AZs for EKS workloads (10.0.32.0/20, 10.0.48.0/20)  
- **Private DB Subnets**: 2 AZs for databases (10.0.64.0/20, 10.0.80.0/20)
- **NAT Gateway**: Single NAT with EIP for cost optimization
- **Security Groups**: Least-privilege access controls
- **NACLs**: Network-level security (optional)
- **VPC Flow Logs**: Traffic monitoring (optional)

### 2. **Container Orchestration** (`modules/eks/`)
- **EKS Cluster**: Managed Kubernetes control plane
- **Fargate Profiles**: Serverless container execution
- **Node Groups**: EC2-based workers (optional)
- **Pod Execution Role**: IAM role for Fargate pods
- **Cluster Addons**: VPC CNI, CoreDNS, kube-proxy
- **OIDC Provider**: For service account authentication

### 3. **Load Balancing** (`modules/eks/`)
- **AWS Load Balancer Controller**: Native ALB integration
- **Ingress Resources**: L7 routing and SSL termination
- **Service Discovery**: Internal cluster networking
- **Health Checks**: Application-aware probes

### 4. **Security & Access Control** (`modules/eks/`)
- **RBAC Configuration**: Role-based access control
- **IAM Roles**: Multi-tier access (admins, developers, viewers)
- **Service Accounts**: Kubernetes identity management
- **Pod Security Standards**: Container security policies
- **Network Policies**: Micro-segmentation (optional)

### 5. **Applications** (`modules/applications/`)
- **Helm Charts**: Kubernetes application packaging (`charts/` directory)
- **ConfigMaps**: Application configuration
- **Secrets**: Sensitive data management
- **Horizontal Pod Autoscaling**: Auto-scaling based on metrics
- **Multi-environment Support**: Dev, staging, prod configurations
- **Integrated Deployment**: Applications deploy with infrastructure automatically

## 🚀 Application Architecture

### Nginx Sample Application

```
┌─────────────────────────────────────────────────────────────────────┐
│                        nginx-sample Application                     │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │                      Ingress (ALB)                              ││
│  │  • Internet-facing load balancer                                ││
│  │  • SSL/TLS termination                                          ││
│  │  • Health checks on /health                                     ││
│  │  • Access logging to S3 (optional)                             ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                 │                                   │
│  ┌─────────────────────────────▼───────────────────────────────────┐│
│  │                     Service (ClusterIP)                        ││
│  │  • Internal load balancing                                      ││
│  │  • Service discovery                                            ││
│  │  • Port mapping (80 → 8080)                                    ││
│  └─────────────────────────────┬───────────────────────────────────┘│
│                                 │                                   │
│  ┌─────────────────────────────▼───────────────────────────────────┐│
│  │                       Deployment                                ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             ││
│  │  │    Pod 1    │  │    Pod 2    │  │    Pod N    │             ││
│  │  │             │  │             │  │             │             ││
│  │  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │             ││
│  │  │ │ nginx   │ │  │ │ nginx   │ │  │ │ nginx   │ │             ││
│  │  │ │ :1.27.3 │ │  │ │ :1.27.3 │ │  │ │ :1.27.3 │ │             ││
│  │  │ │ alpine  │ │  │ │ alpine  │ │  │ │ alpine  │ │             ││
│  │  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │             ││
│  │  │             │  │             │  │             │             ││
│  │  │ ConfigMaps: │  │ ConfigMaps: │  │ ConfigMaps: │             ││
│  │  │ • HTML      │  │ • HTML      │  │ • HTML      │             ││
│  │  │ • nginx.conf│  │ • nginx.conf│  │ • nginx.conf│             ││
│  │  └─────────────┘  └─────────────┘  └─────────────┘             ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

### Security Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Security Layers                             │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │                    Network Security                             ││
│  │  • VPC isolation                                                ││
│  │  • Private subnets for workloads                               ││
│  │  • Security Groups (stateful firewall)                        ││
│  │  • NACLs (stateless firewall)                                 ││
│  │  • No direct internet access for pods                          ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                 │                                   │
│  ┌─────────────────────────────▼───────────────────────────────────┐│
│  │                  Identity & Access Management                   ││
│  │  • IAM roles for different user tiers                          ││
│  │  • Service accounts for pod identity                           ││
│  │  • OIDC provider for secure authentication                     ││
│  │  • RBAC for fine-grained permissions                           ││
│  │  • MFA requirements for privileged access                      ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                 │                                   │
│  ┌─────────────────────────────▼───────────────────────────────────┐│
│  │                    Container Security                           ││
│  │  • Non-root containers (UID 101)                               ││
│  │  • Read-only root filesystem                                   ││
│  │  • Resource limits and requests                                ││
│  │  • Security contexts and capabilities                          ││
│  │  • Pod Security Standards compliance                           ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

## 🔧 Deployment Architecture

### One-Click Deployment Flow

```
Developer runs: terraform apply
                     │
    ┌────────────────▼───────────────┐
    │      Terraform Execution       │
    │                                │
    │  1. Network Module             │
    │     • VPC creation             │
    │     • Subnet provisioning     │
    │     • NAT Gateway setup       │
    │                                │
    │  2. EKS Module                 │
    │     • Cluster creation         │
    │     • Fargate profiles         │
    │     • Load balancer controller │
    │     • RBAC configuration       │
    │                                │
    │  3. Applications Module        │
    │     • Helm releases            │
    │     • ConfigMaps creation      │
    │     • Service definitions      │
    │     • Ingress configuration    │
    └────────────────┬───────────────┘
                     │
    ┌────────────────▼───────────────┐
    │       Ready Environment        │
    │                                │
    │  ✅ Infrastructure deployed    │
    │  ✅ Applications running       │
    │  ✅ Load balancer configured   │
    │  ✅ DNS records ready          │
    │  ✅ Monitoring enabled         │
    └────────────────────────────────┘
```

### Module Dependencies

```
network ──────────────────────────────┐
   │                                  │
   ▼                                  │
  eks ─────────────────────────────────┤
   │                                  │
   ▼                                  │
applications ◄────────────────────────┘

Dependencies:
• applications depends on eks (cluster must exist)
• eks depends on network (VPC and subnets required)
• All modules use shared variables and tags
```

## 📊 Cost Optimization Features

### Infrastructure Efficiency
- **Single NAT Gateway**: Reduces NAT costs by ~50%
- **Fargate Pricing**: Pay-per-pod with no idle EC2 costs
- **Spot Instances**: Optional for non-production workloads
- **Resource Limits**: Prevents resource waste in containers

### Operational Efficiency  
- **One-Click Deployment**: Reduces deployment time and errors
- **Infrastructure as Code**: Eliminates manual configuration
- **Auto Scaling**: Scales resources based on actual demand
- **Health Checks**: Prevents traffic to unhealthy instances

## 🔍 Monitoring & Observability

### Built-in Observability
- **Health Endpoints**: `/health` for application monitoring
- **Nginx Status**: `/nginx-status` for web server metrics
- **Prometheus Metrics**: Ready for metrics collection
- **Structured Logging**: JSON-formatted application logs
- **AWS Load Balancer Logs**: Access logging to S3

### Extensibility Points
- **Prometheus Integration**: Scrape application metrics
- **Grafana Dashboards**: Visualize cluster and application metrics
- **ELK Stack**: Centralized logging solution
- **AWS CloudWatch**: Native AWS monitoring integration
- **Jaeger/Zipkin**: Distributed tracing support

This architecture provides a robust, scalable, and secure foundation for modern cloud-native applications while maintaining simplicity in deployment and management.