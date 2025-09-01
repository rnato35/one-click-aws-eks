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

# ===================================
# RBAC IAM Groups Outputs
# ===================================

output "iam_group_eks_devops_name" {
  description = "Name of the EKS DevOps IAM Group"
  value       = var.enable_rbac ? aws_iam_group.eks_devops[0].name : null
}

output "iam_group_eks_devops_arn" {
  description = "ARN of the EKS DevOps IAM Group"
  value       = var.enable_rbac ? aws_iam_group.eks_devops[0].arn : null
}

output "iam_group_eks_developers_name" {
  description = "Name of the EKS Developers IAM Group"
  value       = var.enable_rbac ? aws_iam_group.eks_developers[0].name : null
}

output "iam_group_eks_developers_arn" {
  description = "ARN of the EKS Developers IAM Group"
  value       = var.enable_rbac ? aws_iam_group.eks_developers[0].arn : null
}

output "iam_group_eks_viewers_name" {
  description = "Name of the EKS Viewers IAM Group"
  value       = var.enable_rbac ? aws_iam_group.eks_viewers[0].name : null
}

output "iam_group_eks_viewers_arn" {
  description = "ARN of the EKS Viewers IAM Group"
  value       = var.enable_rbac ? aws_iam_group.eks_viewers[0].arn : null
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

# ===================================
# RBAC Outputs
# ===================================

output "rbac_roles" {
  description = "Map of RBAC IAM role ARNs for cluster access"
  value = var.enable_rbac ? {
    cluster_admin = try(aws_iam_role.eks_cluster_admins[0].arn, null)
    developer     = try(aws_iam_role.eks_developers[0].arn, null)
    viewer        = try(aws_iam_role.eks_viewers[0].arn, null)
  } : {}
}

output "cluster_admin_role_arn" {
  description = "ARN of the EKS cluster admin IAM role"
  value       = var.enable_rbac ? try(aws_iam_role.eks_cluster_admins[0].arn, null) : null
}

output "developer_role_arn" {
  description = "ARN of the EKS developer IAM role"
  value       = var.enable_rbac ? try(aws_iam_role.eks_developers[0].arn, null) : null
}

output "viewer_role_arn" {
  description = "ARN of the EKS viewer IAM role"
  value       = var.enable_rbac ? try(aws_iam_role.eks_viewers[0].arn, null) : null
}


output "managed_namespaces" {
  description = "List of managed namespaces created"
  value       = keys(var.managed_namespaces)
}

output "rbac_authentication_guide" {
  description = "Quick reference for authenticating to the cluster"
  value = var.enable_rbac ? {
    cluster_admin_command = "aws sts assume-role --profile <your-profile> --role-arn ${try(aws_iam_role.eks_cluster_admins[0].arn, "ROLE_NOT_CREATED")} --role-session-name cluster-admin-session"
    developer_command     = "aws sts assume-role --profile <your-profile> --role-arn ${try(aws_iam_role.eks_developers[0].arn, "ROLE_NOT_CREATED")} --role-session-name developer-session"
    viewer_command        = "aws sts assume-role --profile <your-profile> --role-arn ${try(aws_iam_role.eks_viewers[0].arn, "ROLE_NOT_CREATED")} --role-session-name viewer-session"
    kubectl_config_command = "aws eks update-kubeconfig --region ${data.aws_region.current.region} --name ${aws_eks_cluster.this.id} --profile <your-profile>"
  } : {}
}