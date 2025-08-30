# EKS RBAC Configuration
# This file contains IAM roles and aws-auth ConfigMap setup for EKS cluster access

# ===================================
# Tiered IAM Role Structure
# ===================================

# 1. EKS Cluster Admins - Platform team, break-glass scenarios
resource "aws_iam_role" "eks_cluster_admins" {
  count = var.enable_rbac ? 1 : 0
  name  = "${var.name}-eks-cluster-admins"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.cluster_admin_arns
        }
        Condition = var.require_mfa ? {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
          NumericLessThan = {
            "aws:MultiFactorAuthAge" = "3600"
          }
        } : {}
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.name}-eks-cluster-admins"
    Role        = "cluster-admin"
    Description = "Platform team with full cluster access"
  })
}

# 2. EKS Developers - Application developers, namespace-scoped
resource "aws_iam_role" "eks_developers" {
  count = var.enable_rbac && length(var.developer_arns) > 0 ? 1 : 0
  name  = "${var.name}-eks-developers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.developer_arns
        }
        Condition = var.require_mfa ? {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
          NumericLessThan = {
            "aws:MultiFactorAuthAge" = "7200"
          }
        } : {}
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.name}-eks-developers"
    Role        = "developer"
    Description = "Application developers with namespace-scoped access"
  })
}

# 3. EKS Viewers - Read-only access, monitoring teams
resource "aws_iam_role" "eks_viewers" {
  count = var.enable_rbac && length(var.viewer_arns) > 0 ? 1 : 0
  name  = "${var.name}-eks-viewers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.viewer_arns
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.name}-eks-viewers"
    Role        = "viewer"
    Description = "Read-only access for monitoring and observability teams"
  })
}


# ===================================
# AWS Auth ConfigMap
# ===================================

resource "kubernetes_config_map_v1" "aws_auth" {
  count      = var.enable_rbac ? 1 : 0
  depends_on = [aws_eks_cluster.this]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(
      [
        # Fargate Pod Execution Role
        {
          rolearn  = aws_iam_role.fargate_pod_execution.arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups = [
            "system:bootstrappers",
            "system:nodes",
            "system:node-proxier"
          ]
        }
      ],
      # Cluster Admins
      var.enable_rbac && length(var.cluster_admin_arns) > 0 ? [{
        rolearn  = aws_iam_role.eks_cluster_admins[0].arn
        username = "cluster-admin"
        groups = [
          "system:masters"
        ]
      }] : [],
      # Developers
      var.enable_rbac && length(var.developer_arns) > 0 ? [{
        rolearn  = aws_iam_role.eks_developers[0].arn
        username = "developer"
        groups = [
          "eks:developers"
        ]
      }] : [],
      # Viewers
      var.enable_rbac && length(var.viewer_arns) > 0 ? [{
        rolearn  = aws_iam_role.eks_viewers[0].arn
        username = "viewer"
        groups = [
          "eks:viewers"
        ]
      }] : []
    ))

    mapUsers = length(var.additional_user_mappings) > 0 ? yamlencode(var.additional_user_mappings) : ""
  }
}