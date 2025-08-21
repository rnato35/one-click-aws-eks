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
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_app_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  cluster_version                     = var.eks_cluster_version
  enable_cluster_log_types            = var.eks_enable_cluster_log_types
  log_retention_in_days               = var.eks_log_retention_in_days
  fargate_profiles                    = var.eks_fargate_profiles
  enable_aws_load_balancer_controller = var.eks_enable_aws_load_balancer_controller

  tags = local.tags
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
