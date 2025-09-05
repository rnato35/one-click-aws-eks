# Nginx Sample Application

A sample static website deployment showcasing "By Rnato35" with modern DevOps practices using Kubernetes, Helm, and AWS EKS.

## Overview

This application demonstrates:
- **Container-based deployment** using Nginx Alpine
- **Helm chart management** with environment-specific values
- **AWS Application Load Balancer (ALB)** integration
- **Security best practices** with non-root containers
- **Observability features** with health checks and metrics
- **Multi-environment support** (dev, staging, production)

## Architecture

```
Internet → ALB → EKS Service → Nginx Pods → Custom HTML Content
```

### Components

- **Deployment**: Nginx pods serving custom HTML content
- **Service**: ClusterIP service exposing port 80
- **Ingress**: AWS ALB ingress with SSL/TLS termination
- **ConfigMaps**: Custom HTML content and Nginx configuration
- **ServiceAccount**: Dedicated service account with RBAC
- **HPA**: Horizontal Pod Autoscaler (environment-dependent)

## Directory Structure

```
nginx-sample/
├── Chart.yaml                     # Helm chart metadata
├── values.yaml                    # Base configuration values
├── templates/
│   ├── _helpers.tpl               # Helm template helpers
│   ├── configmap.yaml             # Custom HTML content
│   ├── nginx-config.yaml          # Nginx server configuration
│   ├── deployment.yaml            # Kubernetes deployment
│   ├── service.yaml               # Kubernetes service
│   ├── ingress.yaml               # AWS ALB ingress
│   ├── serviceaccount.yaml        # Service account and RBAC
│   └── hpa.yaml                   # Horizontal Pod Autoscaler
└── README.md                      # This file
```

## Features

### Security
- **Non-root container**: Runs as user ID 101
- **Read-only filesystem**: Enhanced security posture
- **Security headers**: X-Frame-Options, CSP, etc.
- **Resource limits**: CPU and memory constraints
- **Pod Security Standards**: Compliant configuration

### Performance
- **Gzip compression**: Automatic content compression
- **Static asset caching**: Browser caching headers
- **Health checks**: Liveness and readiness probes
- **Horizontal scaling**: Auto-scaling based on CPU/memory

### Observability
- **Health endpoints**: `/health` for load balancer checks
- **Nginx status**: `/nginx-status` (dev environment only)
- **Prometheus metrics**: Ready for monitoring integration
- **Structured logging**: JSON-formatted access logs

## Configuration

### Base Values (`values.yaml`)
```yaml
# Application configuration
message: "By Rnato35"
pageTitle: "Nginx Sample by Rnato35"
environment: "development"

# Image configuration
image:
  repository: nginx
  tag: "1.27.3-alpine"

# Resource limits
resources:
  limits:
    cpu: 200m
    memory: 256Mi
```

### Environment-Specific Overrides

#### Development
- **Single replica**: Cost optimization
- **Internal ALB**: Private access only
- **Debug features**: Nginx status page enabled
- **Lower resources**: 50m CPU, 64Mi memory requests

#### Staging
- **2-5 replicas**: Basic high availability
- **Internet-facing ALB**: Public access
- **Access logging**: ALB logs to S3
- **Production-like**: Similar to prod configuration

#### Production
- **3-10 replicas**: Full high availability
- **SSL/TLS termination**: Certificate management
- **Pod anti-affinity**: Distribution across nodes
- **Conservative scaling**: Slower scale-down

## Deployment

### Prerequisites
1. **EKS Cluster**: Deployed and configured
2. **AWS Load Balancer Controller**: Installed in cluster
3. **kubectl**: Configured to access the cluster
4. **Helm**: Version 3.x installed

### Step 1: Deploy Infrastructure
```bash
cd infra/envs
terraform init
terraform apply -var-file="dev/terraform.tfvars"
```

### Step 2: Configure kubectl
```bash
aws eks update-kubeconfig --name one-click-dev-eks --region us-east-1
```

### Step 3: Deploy Application
```bash
cd k8s/environments/dev
terraform init
terraform apply -var="cluster_name=one-click-dev-eks"
```

### Step 4: Verify Deployment
```bash
# Check pods
kubectl get pods -n apps

# Check service
kubectl get svc -n apps nginx-sample

# Check ingress
kubectl get ingress -n apps nginx-sample
```

## Access Methods

### 1. Port Forward (Development)
```bash
kubectl port-forward -n apps svc/nginx-sample 8080:80
```
Access: http://localhost:8080

### 2. Load Balancer URL
```bash
# Get ALB URL
kubectl get ingress -n apps nginx-sample -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 3. Custom Domain (Production)
Configure DNS to point to the ALB hostname:
```
nginx-sample.yourdomain.com → ALB hostname
```

## Monitoring and Debugging

### Health Checks
```bash
# Application health
kubectl exec -n apps deployment/nginx-sample -- curl localhost:8080/health

# Pod logs
kubectl logs -n apps deployment/nginx-sample -f
```

### Metrics (Development)
```bash
# Port forward to nginx status
kubectl port-forward -n apps svc/nginx-sample 9080:8080

# Access metrics
curl http://localhost:9080/nginx-status
```

### Scaling
```bash
# Manual scaling
kubectl scale deployment -n apps nginx-sample --replicas=3

# Check HPA status
kubectl get hpa -n apps nginx-sample
```

## Customization

### Custom HTML Content
Edit the ConfigMap template in `templates/configmap.yaml`:
```yaml
data:
  index.html: |
    <!-- Your custom HTML here -->
```

### Environment Variables
Modify values in environment-specific files:
```yaml
# k8s/environments/dev/nginx-sample-values.yaml
message: "Your Custom Message"
environment: "development"
```

### Resource Limits
Adjust resources based on load testing:
```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### SSL/TLS Configuration
For HTTPS in production:
```yaml
ingress:
  tls:
    - secretName: nginx-sample-tls
      hosts:
        - nginx-sample.yourdomain.com
  aws:
    certificateArn: "arn:aws:acm:region:account:certificate/cert-id"
```

## Troubleshooting

### Common Issues

#### 1. Pod Not Starting
```bash
kubectl describe pod -n apps -l app.kubernetes.io/name=nginx-sample
```

#### 2. Service Not Accessible
```bash
kubectl get svc -n apps nginx-sample
kubectl describe svc -n apps nginx-sample
```

#### 3. Ingress Not Working
```bash
kubectl describe ingress -n apps nginx-sample
kubectl get events -n apps --sort-by='.lastTimestamp'
```

#### 4. ALB Not Created
Check AWS Load Balancer Controller logs:
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Debug Commands
```bash
# Get all resources
kubectl get all -n apps -l app.kubernetes.io/name=nginx-sample

# Check resource usage
kubectl top pods -n apps -l app.kubernetes.io/name=nginx-sample

# Shell into pod
kubectl exec -it -n apps deployment/nginx-sample -- /bin/sh
```

## Security Considerations

### Network Security
- Use AWS Security Groups to control ALB access
- Implement Network Policies for pod-to-pod communication
- Consider using AWS WAF for additional protection

### Container Security
- Regularly update base images
- Scan images for vulnerabilities
- Use minimal base images (Alpine)
- Run containers as non-root

### Secrets Management
- Use Kubernetes Secrets for sensitive data
- Consider AWS Secrets Manager integration
- Rotate credentials regularly

## Performance Optimization

### Resource Optimization
- Profile application under load
- Adjust resource requests and limits
- Use Vertical Pod Autoscaler for recommendations

### Caching Strategy
- Implement CDN for static assets
- Use browser caching headers
- Consider Redis for dynamic content

### Load Testing
```bash
# Example with Apache Bench
ab -n 1000 -c 10 http://your-alb-hostname/

# Example with kubectl
kubectl run -it --rm load-test --image=busybox --restart=Never -- /bin/sh
```

This application demonstrates enterprise-grade deployment patterns and can serve as a template for deploying production workloads on AWS EKS.