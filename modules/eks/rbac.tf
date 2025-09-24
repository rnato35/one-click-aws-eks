# EKS RBAC Configuration
# This file contains IAM roles and aws-auth ConfigMap setup for EKS cluster access

# ===================================
# Tiered IAM Role Structure
# ===================================

# 1. EKS Cluster Admins - Platform team, break-glass scenarios
resource "aws_iam_role" "eks_cluster_admins" {
  count = var.enable_rbac ? 1 : 0
  name  = "${var.name}-cluster-admins"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
    Name        = "${var.name}-cluster-admins"
    Role        = "cluster-admin"
    Description = "Platform team with full cluster access"
  })
}

# Policy to allow cluster admins to describe EKS cluster (needed for kubectl access)
resource "aws_iam_role_policy" "eks_cluster_admins_describe_cluster" {
  count = var.enable_rbac ? 1 : 0
  name  = "EKSDescribeClusterPolicy"
  role  = aws_iam_role.eks_cluster_admins[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = aws_eks_cluster.this.arn
      }
    ]
  })
}

# 2. EKS Developers - Application developers, namespace-scoped
resource "aws_iam_role" "eks_developers" {
  count = var.enable_rbac ? 1 : 0
  name  = "${var.name}-developers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
    Name        = "${var.name}-developers"
    Role        = "developer"
    Description = "Application developers with namespace-scoped access"
  })
}

# Policy to allow developers to describe EKS cluster (needed for kubectl access)
resource "aws_iam_role_policy" "eks_developers_describe_cluster" {
  count = var.enable_rbac ? 1 : 0
  name  = "EKSDescribeClusterPolicy"
  role  = aws_iam_role.eks_developers[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = aws_eks_cluster.this.arn
      }
    ]
  })
}

# 3. EKS Viewers - Read-only access, monitoring teams
resource "aws_iam_role" "eks_viewers" {
  count = var.enable_rbac ? 1 : 0
  name  = "${var.name}-viewers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.name}-viewers"
    Role        = "viewer"
    Description = "Read-only access for monitoring and observability teams"
  })
}

# Policy to allow viewers to describe EKS cluster (needed for kubectl access)
resource "aws_iam_role_policy" "eks_viewers_describe_cluster" {
  count = var.enable_rbac ? 1 : 0
  name  = "EKSDescribeClusterPolicy"
  role  = aws_iam_role.eks_viewers[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = aws_eks_cluster.this.arn
      }
    ]
  })
}


# ===================================
# AWS Auth ConfigMap - One-Click Compatible
# ===================================

# Generate the aws-auth ConfigMap YAML content
locals {
  aws_auth_configmap = var.enable_rbac ? yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
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
        [{
          rolearn  = aws_iam_role.eks_cluster_admins[0].arn
          username = "cluster-admin"
          groups = [
            "system:masters"
          ]
        }],
        # Developers
        [{
          rolearn  = aws_iam_role.eks_developers[0].arn
          username = "developer"
          groups = [
            "eks:developers"
          ]
        }],
        # Viewers
        [{
          rolearn  = aws_iam_role.eks_viewers[0].arn
          username = "viewer"
          groups = [
            "eks:viewers"
          ]
        }]
      ))
      mapUsers = ""
    }
  }) : ""
}

# Apply aws-auth ConfigMap using kubectl - handles both create and update automatically
resource "null_resource" "aws_auth_apply" {
  count      = var.enable_rbac ? 1 : 0
  depends_on = [aws_eks_cluster.this]

  # Update kubeconfig and apply ConfigMap
  provisioner "local-exec" {
    command = <<-EOT
      # Update kubeconfig  
      aws eks update-kubeconfig --region ${split(":", aws_eks_cluster.this.arn)[3]} --name ${aws_eks_cluster.this.id}
      
      # Apply ConfigMap (creates or updates automatically)
      echo '${local.aws_auth_configmap}' | kubectl apply -f -
    EOT

    environment = {
      AWS_PROFILE = var.aws_profile
    }
  }

  # Clean up on destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Only delete if we manage it
      kubectl delete configmap aws-auth -n kube-system --ignore-not-found=true
    EOT

    environment = {
      AWS_PROFILE = self.triggers.aws_profile
    }
  }

  # Trigger recreation when IAM roles change
  triggers = {
    cluster_admin_role = aws_iam_role.eks_cluster_admins[0].arn
    developer_role     = aws_iam_role.eks_developers[0].arn
    viewer_role        = aws_iam_role.eks_viewers[0].arn
    configmap_content  = local.aws_auth_configmap
    aws_profile        = var.aws_profile
  }
}

# Add variable for aws_profile
variable "aws_profile" {
  description = "AWS profile to use for kubectl commands"
  type        = string
  default     = ""
}