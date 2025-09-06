
module "network" {
  source = "../../modules/network"

  name                     = "${var.project_prefix}-${local.env}"
  cidr_block               = var.vpc_cidr
  azs                      = local.azs
  public_subnet_cidrs      = local.public_subnet_cidrs
  private_app_subnet_cidrs = local.private_app_subnet_cidrs
  private_db_subnet_cidrs  = local.private_db_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  enable_flow_logs   = var.enable_flow_logs
  enable_nacls       = var.enable_nacls
  tags               = local.tags
}

module "eks" {
  count  = var.enable_eks ? 1 : 0
  source = "../../modules/eks"

  name               = "${var.project_prefix}-${local.env}-eks"
  environment        = var.env_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_app_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  cluster_version                     = var.eks_cluster_version
  enable_cluster_log_types            = var.eks_enable_cluster_log_types
  log_retention_in_days               = var.eks_log_retention_in_days
  fargate_profiles                    = var.eks_fargate_profiles
  enable_aws_load_balancer_controller = var.eks_enable_aws_load_balancer_controller

  vpc_cni_addon_version    = var.eks_vpc_cni_addon_version
  coredns_addon_version    = var.eks_coredns_addon_version
  kube_proxy_addon_version = var.eks_kube_proxy_addon_version
  enable_irsa_for_vpc_cni  = var.eks_enable_irsa_for_vpc_cni

  # RBAC Configuration
  enable_rbac             = var.eks_enable_rbac
  require_mfa             = var.eks_require_mfa
  managed_namespaces      = var.eks_managed_namespaces
  enable_network_policies = var.eks_enable_network_policies
  aws_profile             = var.aws_profile

  tags = local.tags

  # Ensure EKS cleanup waits for application cleanup
  depends_on = [module.network]
}

# Applications module - Deploy applications to EKS cluster
module "applications" {
  count  = var.enable_eks && var.enable_applications ? 1 : 0
  source = "../../modules/applications"

  cluster_name = module.eks[0].cluster_id
  environment  = var.env_name
  region       = var.region
  tags         = local.tags

  # Nginx Sample Application Configuration
  nginx_sample = {
    enabled            = var.nginx_sample_enabled
    domain_name        = var.nginx_sample_domain_name
    certificate_arn    = var.nginx_sample_certificate_arn
    replica_count      = var.nginx_sample_replica_count
    enable_autoscaling = var.nginx_sample_enable_autoscaling
    min_replicas       = var.nginx_sample_min_replicas
    max_replicas       = var.nginx_sample_max_replicas
    cpu_limit          = var.nginx_sample_cpu_limit
    memory_limit       = var.nginx_sample_memory_limit
    cpu_request        = var.nginx_sample_cpu_request
    memory_request     = var.nginx_sample_memory_request
  }


  # Wait for EKS cluster to be ready
  depends_on = [module.eks]
}

# Cleanup orchestration resource to ensure proper destroy order
resource "null_resource" "cleanup_orchestrator" {
  count = var.enable_eks && var.enable_applications ? 1 : 0

  triggers = {
    app_cleanup_id = module.applications[0].app_cleanup_id
    cluster_name   = module.eks[0].cluster_id
    timestamp      = timestamp()
  }

  # This resource creates an explicit dependency chain for destroy operations
  # Applications cleanup -> EKS cleanup -> Network cleanup
  depends_on = [
    module.applications,
    module.eks
  ]

  lifecycle {
    create_before_destroy = false
  }
}


# Network outputs
output "vpc_id" { value = module.network.vpc_id }
output "public_subnet_ids" { value = module.network.public_subnet_ids }
output "private_app_subnet_ids" { value = module.network.private_app_subnet_ids }
output "private_db_subnet_ids" { value = module.network.private_db_subnet_ids }

# EKS outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = var.enable_eks ? module.eks[0].cluster_id : null
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = var.enable_eks ? module.eks[0].cluster_arn : null
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : null
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = var.enable_eks ? module.eks[0].cluster_version : null
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = var.enable_eks ? module.eks[0].cluster_certificate_authority_data : null
}

output "eks_oidc_provider_arn" {
  description = "The ARN of the OIDC Identity Provider"
  value       = var.enable_eks ? module.eks[0].oidc_provider_arn : null
}

output "eks_aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = var.enable_eks ? module.eks[0].aws_load_balancer_controller_role_arn : null
}

output "eks_cluster_addons" {
  description = "EKS cluster addons information"
  value       = var.enable_eks ? module.eks[0].cluster_addons : null
}

output "eks_fargate_profile_arns" {
  description = "Amazon Resource Name (ARN) of the EKS Fargate Profiles"
  value       = var.enable_eks ? module.eks[0].fargate_profile_arns : null
}

# RBAC outputs
output "eks_rbac_roles" {
  description = "Map of RBAC IAM role ARNs for cluster access"
  value       = var.enable_eks ? module.eks[0].rbac_roles : {}
}

output "eks_managed_namespaces" {
  description = "List of managed namespaces created"
  value       = var.enable_eks ? module.eks[0].managed_namespaces : []
}

output "eks_rbac_authentication_guide" {
  description = "Quick reference for authenticating to the cluster with different roles"
  value       = var.enable_eks ? module.eks[0].rbac_authentication_guide : {}
}

# Applications outputs
output "nginx_sample_namespace" {
  description = "Namespace where nginx-sample is deployed"
  value       = var.enable_eks && var.enable_applications ? module.applications[0].nginx_sample_namespace : null
}

output "nginx_sample_release_name" {
  description = "Helm release name for nginx-sample"
  value       = var.enable_eks && var.enable_applications ? module.applications[0].nginx_sample_release_name : null
}

output "apps_namespace" {
  description = "Name of the applications namespace"
  value       = var.enable_eks && var.enable_applications ? module.applications[0].apps_namespace : null
}

output "kubectl_commands" {
  description = "Useful kubectl commands for accessing applications"
  value       = var.enable_eks && var.enable_applications ? module.applications[0].kubectl_commands : {}
}
