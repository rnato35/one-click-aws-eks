output "cluster_id" {
  description = "The EKS cluster ID"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.eks_cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "fargate_profile_arns" {
  description = "Amazon Resource Name (ARN) of the EKS Fargate Profiles"
  value       = { for k, v in aws_eks_fargate_profile.this : k => v.arn }
}

output "fargate_profile_ids" {
  description = "EKS Fargate Profile names"
  value       = { for k, v in aws_eks_fargate_profile.this : k => v.fargate_profile_name }
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC Identity Provider"
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller[0].arn : null
}

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value = {
    vpc-cni    = aws_eks_addon.vpc_cni
    coredns    = aws_eks_addon.coredns
    kube-proxy = aws_eks_addon.kube_proxy
  }
}

output "vpc_cni_addon" {
  description = "VPC CNI addon information"
  value = {
    arn           = aws_eks_addon.vpc_cni.arn
    addon_version = aws_eks_addon.vpc_cni.addon_version
  }
}

output "coredns_addon" {
  description = "CoreDNS addon information"
  value = {
    arn           = aws_eks_addon.coredns.arn
    addon_version = aws_eks_addon.coredns.addon_version
  }
}

output "kube_proxy_addon" {
  description = "Kube-proxy addon information"
  value = {
    arn           = aws_eks_addon.kube_proxy.arn
    addon_version = aws_eks_addon.kube_proxy.addon_version
  }
}