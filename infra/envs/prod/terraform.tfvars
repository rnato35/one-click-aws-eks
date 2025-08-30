env_name    = "prod"
region      = "us-east-1"
aws_profile = "rnato35"

# Networking
vpc_cidr = "10.2.0.0/16"
az_count = 3

# Features
enable_nat_gateway = true
single_nat_gateway = false  # Multiple NAT gateways for HA in production
enable_flow_logs   = true
enable_nacls       = true

# EKS
enable_eks                              = true
eks_cluster_version                     = "1.33"
eks_enable_cluster_log_types            = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
eks_log_retention_in_days               = 30  # Longer retention for production
eks_enable_aws_load_balancer_controller = true

# RBAC Configuration
eks_enable_rbac = true
eks_cluster_admin_arns = [
  # Add your IAM user ARN here for admin access
  "arn:aws:iam::825982271549:user/rmendoza"
]
eks_developer_arns = [
  # Add developer IAM user/role ARNs here - they will get READ-ONLY access in production
  # "arn:aws:iam::825982271549:user/developer1",
  # "arn:aws:iam::825982271549:user/developer2"
]
eks_viewer_arns = [
  # Add viewer IAM user/role ARNs here (monitoring, support teams)
  # "arn:aws:iam::825982271549:user/monitoring-user"
]
eks_require_mfa = true  # MFA required for production

# Managed Namespaces
eks_managed_namespaces = {
  apps = {
    labels = {
      "app.kubernetes.io/environment" = "production"
      "app.kubernetes.io/tier"        = "application"
      "team"                          = "platform"
    }
    annotations = {
      "description" = "Main application namespace for production"
      "contact"     = "renato@renatomendoza.io"
    }
    developer_access = ["read"]  # Read-only access in production
  }
  # Monitoring namespace for production
  monitoring = {
    labels = {
      "app.kubernetes.io/environment" = "production"
      "app.kubernetes.io/tier"        = "monitoring"
    }
    annotations = {
      "description" = "Monitoring and observability tools for production"
    }
    developer_access = ["read"]  # Read-only access in production
  }
  # System namespace for production
  system = {
    labels = {
      "app.kubernetes.io/environment" = "production"
      "app.kubernetes.io/tier"        = "system"
    }
    annotations = {
      "description" = "System tools and utilities for production"
    }
    developer_access = []  # No developer access to system namespace
  }
}

eks_enable_network_policies = true  # Enable network isolation for production
