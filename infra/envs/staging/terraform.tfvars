env_name    = "staging"
region      = "us-east-1"
aws_profile = "rnato35"

# Networking
vpc_cidr = "10.1.0.0/16"
az_count = 2

# Features
enable_nat_gateway = true
single_nat_gateway = true
enable_flow_logs   = true
enable_nacls       = false

# EKS
enable_eks                              = true
eks_cluster_version                     = "1.33"
eks_enable_cluster_log_types            = ["api", "audit"]
eks_log_retention_in_days               = 14
eks_enable_aws_load_balancer_controller = true

# RBAC Configuration - Using IAM Groups
# Users should be added to the appropriate IAM Groups:
# - {cluster-name}-eks-devops: Full admin access to all environments
# - {cluster-name}-eks-developers: Read-only access to apps namespace in staging
# - {cluster-name}-eks-viewers: Read-only access to all environments
eks_enable_rbac = true
eks_require_mfa = true # MFA required for staging

# Managed Namespaces
eks_managed_namespaces = {
  apps = {
    labels = {
      "app.kubernetes.io/environment" = "staging"
      "app.kubernetes.io/tier"        = "application"
      "team"                          = "platform"
    }
    annotations = {
      "description" = "Main application namespace for staging"
      "contact"     = "renato@renatomendoza.io"
    }
    developer_access = ["read"] # Read-only access in staging
  }
  # Monitoring namespace for staging
  monitoring = {
    labels = {
      "app.kubernetes.io/environment" = "staging"
      "app.kubernetes.io/tier"        = "monitoring"
    }
    annotations = {
      "description" = "Monitoring and observability tools for staging"
    }
    developer_access = ["read"] # Read-only access in staging
  }
}

eks_enable_network_policies = true # Enable network isolation for staging
