# Nginx Sample Application - Deployment Guide

This guide walks you through deploying the complete infrastructure INCLUDING the Nginx sample application showing "By Rnato35" with a single command.

## 🎯 One-Click Deployment

### Prerequisites ✅

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** version >= 1.6.0 installed
3. **kubectl** installed (for accessing the cluster)

### Deploy Everything with One Command 🚀

```bash
# 1. Navigate to the infrastructure directory
cd infra/envs

# 2. Initialize Terraform (first time only)
terraform init

# 3. Deploy EVERYTHING - Infrastructure + Applications
terraform apply -var-file="dev/terraform.tfvars"
```

**That's it!** ✨ One command deploys:
- ✅ VPC with public/private subnets
- ✅ EKS cluster with Fargate profiles  
- ✅ AWS Load Balancer Controller
- ✅ RBAC configuration
- ✅ Nginx sample application

### Configure kubectl Access ⚙️

After deployment completes, configure kubectl to access your cluster:

```bash
# Update kubeconfig
aws eks update-kubeconfig --name one-click-dev-eks --region us-east-1
```

### Verify Deployment ✔️

```bash
# Check if nginx-sample pods are running
kubectl get pods -n apps -l app.kubernetes.io/name=nginx-sample

# Expected output:
# NAME                            READY   STATUS    RESTARTS   AGE
# nginx-sample-xxxx-xxxx         1/1     Running   0          2m

# Get useful kubectl commands from Terraform output
terraform output kubectl_commands
```

## Access Your Application

### Method 1: Port Forward (Quick Access)
```bash
# Forward port 8080 to the service
kubectl port-forward -n apps svc/nginx-sample 8080:80

# Open in browser
open http://localhost:8080
```

### Method 2: Load Balancer URL (Production Access)
```bash
# Get the ALB hostname
ALB_URL=$(kubectl get ingress -n apps nginx-sample -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$ALB_URL"

# Open in browser (wait 2-3 minutes for ALB to be ready)
open "http://$ALB_URL"
```

## What You'll See 🎨

Your application will display:
- **Modern, responsive design** with gradient background
- **"By Rnato35" message** prominently displayed
- **Technology badges**: AWS EKS, Kubernetes, Helm, Terraform, Nginx
- **Environment indicator** showing "DEV" environment
- **Cluster information** showing your EKS cluster name

## Application Architecture

```
Internet/User
     ↓
Application Load Balancer (ALB)
     ↓ 
Kubernetes Service (nginx-sample)
     ↓
Nginx Pods (serving custom HTML)
```

### Key Components Created:

1. **Kubernetes Deployment**: Nginx pods with custom HTML
2. **Service**: ClusterIP service exposing the application
3. **Ingress**: AWS ALB ingress for external access
4. **ConfigMaps**: Custom HTML content and Nginx configuration
5. **ServiceAccount**: Dedicated service account with proper RBAC

All components are deployed automatically as part of the infrastructure deployment - no separate Kubernetes management needed!

## 🏗️ Architecture Overview

The deployment creates a complete three-tier architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                     Internet Gateway                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              Application Load Balancer                      │
│                  (Public Subnets)                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                EKS Fargate Pods                            │
│              (Private App Subnets)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐    │
│  │nginx-sample │  │observability│  │ Other Apps      │    │
│  │    pods     │  │    test     │  │   (future)      │    │
│  └─────────────┘  └─────────────┘  └─────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 🎛️ Configuration Options

All applications are configured via Terraform variables in `infra/envs/dev/terraform.tfvars`:

### Available Configuration Variables
```hcl
# Enable/disable application deployment
enable_applications = true

# Nginx Sample Configuration  
nginx_sample_enabled = true
nginx_sample_domain_name = "nginx-sample.local"
nginx_sample_replica_count = 1
nginx_sample_enable_autoscaling = false
```

## Customization Options

### Change the Message
Edit the environment-specific values file:
```yaml
# k8s/environments/dev/nginx-sample-values.yaml
message: "Your Custom Message Here"
pageTitle: "Your Custom Title"
```

Then redeploy:
```bash
terraform apply -var="cluster_name=one-click-dev-eks"
```

### Scale the Application
```bash
# Manual scaling
kubectl scale deployment -n apps nginx-sample --replicas=3

# Check scaling
kubectl get pods -n apps -l app.kubernetes.io/name=nginx-sample
```

### Enable Autoscaling
Edit values to enable HPA:
```yaml
# k8s/environments/dev/nginx-sample-values.yaml
autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 80
```

## Monitoring and Health Checks

### Application Health
```bash
# Check application health endpoint
kubectl exec -n apps deployment/nginx-sample -- curl -s localhost:8080/health

# Expected output: "healthy"
```

### Pod Status
```bash
# Check pod logs
kubectl logs -n apps deployment/nginx-sample -f

# Check pod details
kubectl describe pod -n apps -l app.kubernetes.io/name=nginx-sample
```

### Load Balancer Status
```bash
# Check ingress status
kubectl get ingress -n apps nginx-sample

# Check ALB in AWS Console
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `nginx-sample`)]'
```

## Troubleshooting

### Pod Not Starting
```bash
# Check pod events
kubectl describe pod -n apps -l app.kubernetes.io/name=nginx-sample

# Common issues:
# - Image pull errors
# - Resource constraints
# - Configuration errors
```

### Can't Access Application
```bash
# Check service
kubectl get svc -n apps nginx-sample

# Check ingress
kubectl describe ingress -n apps nginx-sample

# Check ALB Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller -f
```

### Application Shows Error Page
```bash
# Check nginx configuration
kubectl get configmap -n apps nginx-sample-nginx-config -o yaml

# Check HTML content
kubectl get configmap -n apps nginx-sample-html -o yaml
```

## Security Features

Your application includes several security best practices:

1. **Non-root containers**: Pods run as user ID 101
2. **Read-only root filesystem**: Enhanced security posture
3. **Resource limits**: Prevents resource exhaustion
4. **Security headers**: X-Frame-Options, CSP, etc.
5. **Network policies**: (Optional) Pod-to-pod communication control

## Performance Optimization

### Resource Usage
```bash
# Check current resource usage
kubectl top pods -n apps -l app.kubernetes.io/name=nginx-sample

# Check resource limits
kubectl describe pod -n apps -l app.kubernetes.io/name=nginx-sample | grep -A 6 Resources
```

### Load Testing
```bash
# Simple load test with Apache Bench
ab -n 1000 -c 10 http://your-alb-hostname/

# Or use kubectl for internal testing
kubectl run load-test --image=busybox --rm -it --restart=Never -- /bin/sh
```

## Clean Up

To remove the application:
```bash
cd k8s/environments/dev
terraform destroy -var="cluster_name=one-click-dev-eks"
```

## Next Steps

1. **Custom Domain**: Configure Route53 for a custom domain name
2. **SSL/TLS**: Add HTTPS with ACM certificates
3. **Monitoring**: Integrate with Prometheus and Grafana
4. **CI/CD**: Set up automated deployments
5. **Multi-environment**: Deploy to staging and production

## Support

For issues or questions:
1. Check the application logs: `kubectl logs -n apps deployment/nginx-sample`
2. Review the troubleshooting section above
3. Check AWS Load Balancer Controller documentation
4. Verify RBAC permissions are correctly configured

---

**Congratulations! 🎉** You've successfully deployed a production-ready web application on AWS EKS using Infrastructure as Code principles.