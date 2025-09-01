# IAM Groups for EKS RBAC
# This file defines IAM groups that will be used for EKS access control
# Users can be added to these groups externally, and the groups will have the appropriate EKS permissions

# ===================================
# IAM Groups
# ===================================

# DevOps Group - Full admin access to all environments
resource "aws_iam_group" "eks_devops" {
  count = var.enable_rbac ? 1 : 0
  name  = "${var.name}-devops"
  path  = "/eks/"
}

# Developers Group - Environment-specific access
resource "aws_iam_group" "eks_developers" {
  count = var.enable_rbac ? 1 : 0
  name  = "${var.name}-developers"
  path  = "/eks/"
}

# Viewers Group - Read-only access to all environments
resource "aws_iam_group" "eks_viewers" {
  count = var.enable_rbac ? 1 : 0
  name  = "${var.name}-viewers"
  path  = "/eks/"
}

# ===================================
# IAM Group Policies
# ===================================

# Policy for DevOps group to assume the cluster admin role
resource "aws_iam_group_policy" "eks_devops_assume_role" {
  count = var.enable_rbac ? 1 : 0
  name  = "AssumeClusterAdminRole"
  group = aws_iam_group.eks_devops[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.eks_cluster_admins[0].arn
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
}

# Policy for Developers group to assume the developer role
resource "aws_iam_group_policy" "eks_developers_assume_role" {
  count = var.enable_rbac ? 1 : 0
  name  = "AssumeDeveloperRole"
  group = aws_iam_group.eks_developers[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.eks_developers[0].arn
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
}

# Policy for Viewers group to assume the viewer role
resource "aws_iam_group_policy" "eks_viewers_assume_role" {
  count = var.enable_rbac ? 1 : 0
  name  = "AssumeViewerRole"
  group = aws_iam_group.eks_viewers[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.eks_viewers[0].arn
      }
    ]
  })
}