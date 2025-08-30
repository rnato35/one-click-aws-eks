# EKS Authentication Guide

This guide explains how to authenticate to the EKS cluster using the configured RBAC roles.

## Overview

The EKS cluster is configured with a tiered RBAC system that provides different levels of access:

- **🔴 Cluster Admins**: Full cluster access (platform team, break-glass scenarios)
- **🟡 Developers**: Namespace-scoped access to application workloads
- **🟢 Viewers**: Read-only access for monitoring and troubleshooting
- **🔵 CI/CD**: Automated deployment permissions

## Prerequisites

Before you can access the cluster, ensure you have:

1. **AWS CLI** installed and configured
2. **kubectl** installed (version 1.28+)
3. **IAM permissions** to assume one of the RBAC roles
4. **MFA device** configured (if MFA is required)

## Authentication Methods

### Method 1: Direct Role Assumption (Recommended for Developers)

#### Step 1: Assume the Appropriate Role

```bash
# For Cluster Admins
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-eks-cluster-admins \
  --role-session-name cluster-admin-session \
  --profile YOUR_PROFILE

# For Developers
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-eks-developers \
  --role-session-name developer-session \
  --profile YOUR_PROFILE

# For Viewers
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-eks-viewers \
  --role-session-name viewer-session \
  --profile YOUR_PROFILE

# For CI/CD
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-eks-ci-cd \
  --role-session-name ci-cd-session \
  --profile YOUR_PROFILE
```

#### Step 2: Export Temporary Credentials

```bash
# From the output of the assume-role command, export:
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
```

#### Step 3: Update kubectl Configuration

```bash
aws eks update-kubeconfig \
  --region REGION \
  --name CLUSTER_NAME \
  --alias CLUSTER_NAME-ROLE_NAME
```

### Method 2: Profile-Based Authentication

#### Step 1: Configure AWS Profile with Role

Create or update `~/.aws/config`:

```ini
[profile eks-admin]
role_arn = arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-eks-cluster-admins
source_profile = your-base-profile
mfa_serial = arn:aws:iam::ACCOUNT_ID:mfa/your-username  # If MFA required

[profile eks-developer]
role_arn = arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-eks-developers
source_profile = your-base-profile
mfa_serial = arn:aws:iam::ACCOUNT_ID:mfa/your-username  # If MFA required

[profile eks-viewer]
role_arn = arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-eks-viewers
source_profile = your-base-profile

[profile eks-ci-cd]
role_arn = arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-eks-ci-cd
source_profile = your-base-profile
```

#### Step 2: Update kubectl Configuration

```bash
# For each role you want to use:
aws eks update-kubeconfig \
  --region REGION \
  --name CLUSTER_NAME \
  --profile eks-admin \
  --alias CLUSTER_NAME-admin

aws eks update-kubeconfig \
  --region REGION \
  --name CLUSTER_NAME \
  --profile eks-developer \
  --alias CLUSTER_NAME-developer

aws eks update-kubeconfig \
  --region REGION \
  --name CLUSTER_NAME \
  --profile eks-viewer \
  --alias CLUSTER_NAME-viewer
```

## Role Permissions

### Cluster Admin
- **Scope**: Entire cluster
- **Permissions**: Full administrative access (system:masters group)
- **Use Cases**: Platform operations, emergency access, cluster maintenance
- **Namespaces**: All

### Developer
- **Scope**: Application namespaces only
- **Permissions**: Create, read, update, delete application resources
- **Use Cases**: Application development, debugging, deployment
- **Namespaces**: `apps`, and other configured developer namespaces
- **Resources**: Pods, Services, Deployments, ConfigMaps, Secrets, Ingresses, HPA

### Viewer
- **Scope**: Cluster-wide read access
- **Permissions**: Read-only access to all resources
- **Use Cases**: Monitoring, troubleshooting, observability
- **Namespaces**: All (read-only)
- **Resources**: All resources (read-only), metrics

### CI/CD
- **Scope**: Deployment namespaces
- **Permissions**: Deploy and manage applications
- **Use Cases**: Automated deployments, GitOps
- **Namespaces**: Configured CI/CD namespaces
- **Resources**: Deployments, Services, ConfigMaps, Secrets, Ingresses

## Quick Commands

### Test Your Access

```bash
# Check your current identity
kubectl config current-context
aws sts get-caller-identity

# Test cluster access
kubectl get nodes
kubectl get namespaces

# Test namespace-specific access (developers)
kubectl get pods -n apps
kubectl describe deployment -n apps

# Test read-only access (viewers)
kubectl get all --all-namespaces
kubectl top nodes
```

### Switch Between Contexts

```bash
# List available contexts
kubectl config get-contexts

# Switch context
kubectl config use-context CLUSTER_NAME-admin
kubectl config use-context CLUSTER_NAME-developer
kubectl config use-context CLUSTER_NAME-viewer
```

### Create Aliases (Optional)

Add to your shell profile (`~/.bashrc`, `~/.zshrc`):

```bash
# EKS Context Aliases
alias k8s-admin='kubectl config use-context CLUSTER_NAME-admin'
alias k8s-dev='kubectl config use-context CLUSTER_NAME-developer'
alias k8s-view='kubectl config use-context CLUSTER_NAME-viewer'

# Quick kubectl with current context
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
```

## Troubleshooting

### Common Issues

#### "You must be logged in to the server"
- **Cause**: Invalid or expired credentials
- **Solution**: Re-assume the role or refresh your AWS credentials

#### "User is not authorized to perform eks:DescribeCluster"
- **Cause**: Your IAM user/role is not in the allowed ARNs list
- **Solution**: Contact your platform team to add your ARN to the appropriate role

#### "Forbidden: User cannot get resource"
- **Cause**: Insufficient Kubernetes RBAC permissions
- **Solution**: Verify you're using the correct role for the operation

#### MFA Token Issues
- **Cause**: MFA required but not provided, or token expired
- **Solution**: Provide valid MFA token when assuming role

### Debug Commands

```bash
# Check AWS identity
aws sts get-caller-identity

# Check kubectl configuration
kubectl config view --minify

# Test EKS token generation
aws eks get-token --cluster-name CLUSTER_NAME --region REGION

# Describe your permissions (as cluster admin)
kubectl auth can-i --list --as system:serviceaccount:default:default

# Check aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml
```

## Security Best Practices

1. **Use MFA**: Enable MFA for all role assumptions in production
2. **Least Privilege**: Only assume roles with the minimum required permissions
3. **Short Sessions**: Use short session durations for role assumptions
4. **Regular Rotation**: Rotate access keys and review role assignments regularly
5. **Audit Logs**: Monitor CloudTrail and EKS audit logs for access patterns
6. **Network Security**: Access cluster from trusted networks only

## Getting Help

If you experience authentication issues:

1. Check this documentation first
2. Try the troubleshooting steps above
3. Contact the platform team with:
   - Your IAM user/role ARN
   - The specific error message
   - The kubectl context you're trying to use
   - Your AWS CLI version and configuration

---

**Note**: Replace `ACCOUNT_ID`, `CLUSTER_NAME`, and `REGION` with your actual values. These can be found in the Terraform outputs after deployment.