# EKS Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the EKS cluster, authentication, and RBAC.

## Table of Contents

1. [Authentication Issues](#authentication-issues)
2. [RBAC Permission Issues](#rbac-permission-issues)
3. [Networking Issues](#networking-issues)
4. [Application Deployment Issues](#application-deployment-issues)
5. [Monitoring and Logging](#monitoring-and-logging)
6. [Performance Issues](#performance-issues)
7. [Useful Commands](#useful-commands)

## Authentication Issues

### Issue: "You must be logged in to the server"

**Symptoms**:
```bash
kubectl get nodes
# Error: You must be logged in to the server (the server has asked for the client to provide credentials)
```

**Possible Causes & Solutions**:

1. **AWS credentials not configured**:
   ```bash
   # Check current identity
   aws sts get-caller-identity
   
   # If no output, configure AWS CLI
   aws configure --profile your-profile
   ```

2. **Wrong AWS profile**:
   ```bash
   # Check current profile
   echo $AWS_PROFILE
   
   # Set correct profile
   export AWS_PROFILE=your-eks-profile
   ```

3. **kubeconfig not updated**:
   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig --region us-east-1 --name your-cluster-name --profile your-profile
   ```

4. **Role assumption required**:
   ```bash
   # Assume the correct role
   aws sts assume-role \
     --role-arn arn:aws:iam::ACCOUNT:role/CLUSTER-eks-developers \
     --role-session-name developer-session
     
   # Export the temporary credentials
   export AWS_ACCESS_KEY_ID="ASIA..."
   export AWS_SECRET_ACCESS_KEY="..."
   export AWS_SESSION_TOKEN="..."
   ```

### Issue: "An error occurred (UnauthorizedOperation) when calling the AssumeRole operation"

**Symptoms**:
```bash
aws sts assume-role --role-arn arn:aws:iam::123:role/eks-developers --role-session-name test
# An error occurred (AccessDenied) when calling the AssumeRole operation
```

**Solutions**:

1. **Check IAM permissions**:
   ```bash
   # Verify your user has sts:AssumeRole permission
   aws iam get-user-policy --user-name your-username --policy-name AssumeRolePolicy
   ```

2. **Check role trust relationship**:
   - Verify your IAM user/role ARN is in the role's trust policy
   - Ensure the role exists and you have the correct ARN

3. **MFA requirement**:
   ```bash
   # If MFA is required, include MFA token
   aws sts assume-role \
     --role-arn arn:aws:iam::ACCOUNT:role/CLUSTER-eks-developers \
     --role-session-name developer-session \
     --serial-number arn:aws:iam::ACCOUNT:mfa/your-username \
     --token-code 123456
   ```

### Issue: "User is not authorized to perform eks:DescribeCluster"

**Symptoms**:
```bash
aws eks describe-cluster --name your-cluster
# User: arn:aws:iam::123:user/username is not authorized to perform: eks:DescribeCluster
```

**Solutions**:

1. **Missing IAM permissions**:
   - Add `eks:DescribeCluster` permission to your IAM user/role
   - Or use the correct RBAC role that has cluster access

2. **Use correct profile**:
   ```bash
   aws eks describe-cluster --name your-cluster --profile eks-admin
   ```

## RBAC Permission Issues

### Issue: "Forbidden: user cannot get resource"

**Symptoms**:
```bash
kubectl get pods -n apps
# Error from server (Forbidden): pods is forbidden: User "developer" cannot get resource "pods" in API group "" in the namespace "apps"
```

**Diagnosis Steps**:

1. **Check current user identity**:
   ```bash
   kubectl auth whoami
   # or
   aws sts get-caller-identity
   ```

2. **Check user permissions**:
   ```bash
   # Test specific permission
   kubectl auth can-i get pods -n apps
   
   # List all permissions for current user
   kubectl auth can-i --list -n apps
   ```

3. **Check RBAC configuration**:
   ```bash
   # Check RoleBindings in the namespace
   kubectl get rolebindings -n apps -o yaml
   
   # Check ClusterRoleBindings
   kubectl get clusterrolebindings | grep eks
   
   # Describe specific binding
   kubectl describe clusterrolebinding eks:developers
   ```

**Solutions**:

1. **Wrong Kubernetes context**:
   ```bash
   # Check current context
   kubectl config current-context
   
   # Switch to correct context
   kubectl config use-context your-cluster-developer
   ```

2. **User not in correct group**:
   ```bash
   # Check aws-auth ConfigMap
   kubectl get configmap aws-auth -n kube-system -o yaml
   
   # Verify your IAM role is mapped to correct Kubernetes groups
   ```

3. **Missing RoleBinding**:
   - Verify the namespace has the correct RoleBindings
   - Check if RBAC resources were created by Terraform

### Issue: "User cannot create resource in namespace"

**Solutions**:

1. **Check namespace access configuration**:
   ```bash
   # Verify namespace exists and has correct labels
   kubectl get namespace apps --show-labels
   
   # Check if user has write access to namespace
   kubectl auth can-i create deployments -n apps
   ```

2. **Review managed namespace configuration**:
   - Check Terraform variable `eks_managed_namespaces`
   - Ensure your user's role has `developer_access = ["write"]`

## Networking Issues

### Issue: Pods cannot communicate with each other

**Diagnosis**:
```bash
# Check pod networking
kubectl get pods -o wide
kubectl describe pod <pod-name>

# Test connectivity between pods
kubectl exec -it <pod1> -- ping <pod2-ip>

# Check NetworkPolicies
kubectl get networkpolicies -A
```

**Solutions**:

1. **NetworkPolicy blocking traffic**:
   ```bash
   # If network policies are enabled, check for default deny
   kubectl get networkpolicy default-deny-all -n apps
   
   # Check allow policies
   kubectl get networkpolicy allow-same-namespace -n apps -o yaml
   ```

2. **Security group issues**:
   ```bash
   # Check EKS cluster security groups
   aws eks describe-cluster --name your-cluster --query 'cluster.resourcesVpcConfig.securityGroupIds'
   ```

### Issue: Cannot access services from outside cluster

**Diagnosis**:
```bash
# Check service configuration
kubectl get services -A
kubectl describe service <service-name> -n <namespace>

# Check ingress
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>
```

**Solutions**:

1. **Load Balancer not created**:
   ```bash
   # Check AWS Load Balancer Controller
   kubectl get deployment -n kube-system aws-load-balancer-controller
   
   # Check controller logs
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   ```

2. **Security group not allowing traffic**:
   - Check ALB security groups
   - Verify inbound rules for required ports

## Application Deployment Issues

### Issue: Pods stuck in Pending state

**Diagnosis**:
```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check node capacity
kubectl describe nodes
```

**Common Causes & Solutions**:

1. **Resource constraints**:
   ```bash
   # Check resource requests vs available
   kubectl top nodes
   kubectl describe node <node-name>
   ```

2. **Fargate profile issues**:
   ```bash
   # Check Fargate profiles
   aws eks describe-fargate-profile --cluster-name your-cluster --fargate-profile-name apps
   
   # Verify namespace and labels match Fargate selectors
   kubectl get namespace apps --show-labels
   ```

3. **Image pull issues**:
   ```bash
   # Check if image exists and is accessible
   kubectl describe pod <pod-name> | grep -A5 "Failed to pull image"
   
   # Check image pull secrets
   kubectl get secrets -n <namespace>
   ```

### Issue: Deployment fails with ImagePullBackOff

**Solutions**:

1. **Check image name and tag**:
   ```bash
   kubectl describe pod <pod-name> | grep Image
   ```

2. **ECR authentication** (if using ECR):
   ```bash
   # Update ECR login
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
   ```

3. **Check image pull secrets**:
   ```bash
   # Create ECR secret if needed
   kubectl create secret docker-registry ecr-secret \
     --docker-server=<account>.dkr.ecr.us-east-1.amazonaws.com \
     --docker-username=AWS \
     --docker-password=$(aws ecr get-login-password --region us-east-1) \
     -n <namespace>
   ```

## Monitoring and Logging

### Checking Cluster Health

```bash
# Cluster status
kubectl get componentstatuses
kubectl get nodes
kubectl cluster-info

# System pods
kubectl get pods -n kube-system

# Resource usage
kubectl top nodes
kubectl top pods -A
```

### Accessing Logs

```bash
# Pod logs
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>  # Follow logs

# Previous container logs (if pod restarted)
kubectl logs <pod-name> -n <namespace> --previous

# All containers in a pod
kubectl logs <pod-name> -n <namespace> --all-containers

# EKS control plane logs (CloudWatch)
aws logs describe-log-groups --log-group-name-prefix /aws/eks/your-cluster
```

### Common Log Locations

- **EKS Control Plane**: CloudWatch Logs `/aws/eks/your-cluster/`
- **Application Logs**: `kubectl logs`
- **System Logs**: `kubectl logs -n kube-system`
- **AWS Load Balancer Controller**: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`

## Performance Issues

### High CPU/Memory Usage

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory

# Check resource limits
kubectl describe pod <pod-name> | grep -A5 "Limits\|Requests"

# Check HPA status
kubectl get hpa -A
kubectl describe hpa <hpa-name>
```

### Slow API Responses

```bash
# Check API server logs in CloudWatch
# Look for:
# - Authentication latency
# - Authorization latency
# - Admission controller latency

# Check etcd performance (control plane logs)
# Look for slow etcd operations

# Check network latency between nodes
kubectl run test-pod --image=busybox --rm -it --restart=Never -- ping <node-ip>
```

## Useful Commands

### Emergency Access (Break Glass)

```bash
# If locked out, use cluster admin role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT:role/CLUSTER-eks-cluster-admins \
  --role-session-name emergency-access

# Update kubeconfig with admin profile
aws eks update-kubeconfig --region us-east-1 --name your-cluster --profile eks-admin
```

### Debugging kubectl

```bash
# Verbose kubectl output
kubectl get pods -v=6    # Basic debug info
kubectl get pods -v=8    # Detailed debug info
kubectl get pods -v=9    # Very detailed debug info

# Raw API response
kubectl get pods -o json | jq '.'

# Explain resources
kubectl explain pod.spec.containers
kubectl explain deployment.spec
```

### Checking Terraform State

```bash
# Check current EKS resources in Terraform
terraform show | grep eks
terraform state list | grep eks

# Check specific resource
terraform state show 'module.eks[0].aws_eks_cluster.this'
```

### AWS CLI Debugging

```bash
# Enable AWS CLI debug output
aws --debug eks describe-cluster --name your-cluster 2>&1 | head -50

# Check AWS CLI configuration
aws configure list
aws configure list-profiles

# Test AWS API access
aws sts get-caller-identity
aws eks list-clusters
```

### Emergency Procedures

#### Complete Loss of Access

1. **Check AWS Console EKS access**
2. **Use root account to update aws-auth ConfigMap**
3. **Create emergency admin user via AWS Console**
4. **Update Terraform state to match**

#### Cluster Unresponsive

1. **Check AWS EKS console for cluster status**
2. **Review CloudWatch logs for control plane**
3. **Check VPC and networking configuration**
4. **Verify security groups and NACLs**

#### Mass Permission Changes Needed

1. **Use Terraform to make changes**
2. **Test changes in dev environment first**
3. **Apply changes during maintenance window**
4. **Have rollback plan ready**

---

## Getting Additional Help

If you cannot resolve the issue using this guide:

1. **Collect diagnostic information**:
   - kubectl version
   - aws --version
   - Current AWS identity (`aws sts get-caller-identity`)
   - kubectl config (`kubectl config view --minify`)
   - Error messages (full text)

2. **Check official documentation**:
   - [AWS EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
   - [Kubernetes Documentation](https://kubernetes.io/docs/tasks/debug-application-cluster/)

3. **Contact platform team** with collected information

**Remember**: Always test fixes in a development environment before applying to production!