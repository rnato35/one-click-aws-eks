env_name    = "dev"
region      = "us-east-1"
aws_profile = "rnato35"

# Networking
vpc_cidr = "10.0.0.0/16"
az_count = 2

# Features
enable_nat_gateway = true
single_nat_gateway = true
enable_flow_logs   = false
enable_nacls       = false

# EKS
enable_eks                              = true
eks_cluster_version                     = "1.33"
eks_enable_cluster_log_types            = ["api", "audit"]
eks_log_retention_in_days               = 7
eks_enable_aws_load_balancer_controller = true

# RBAC Configuration - Using IAM Groups
# Users should be added to the appropriate IAM Groups:
# - {cluster-name}-eks-devops: Full admin access to all environments
# - {cluster-name}-eks-developers: Read/Write to apps namespace in dev, Read-only in staging/prod
# - {cluster-name}-eks-viewers: Read-only access to all environments
eks_enable_rbac = true
eks_require_mfa = false      # Set to true for production

# Managed Namespaces
eks_managed_namespaces = {
  apps = {
    labels = {
      "app.kubernetes.io/environment" = "development"
      "app.kubernetes.io/tier"        = "application"
      "team"                          = "platform"
    }
    annotations = {
      "description" = "Main application namespace for developers"
      "contact"     = "renato@renatomendoza.io"
    }
    developer_access = ["write"]
  }
  # Example of additional namespace
  # monitoring = {
  #   labels = {
  #     "app.kubernetes.io/environment" = "development"
  #     "app.kubernetes.io/tier"        = "monitoring"
  #   }
  #   annotations = {
  #     "description" = "Monitoring and observability tools"
  #   }
  #   developer_access = []
  # }
}

eks_enable_network_policies = false  # Enable for network isolation between namespaces
