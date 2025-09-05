# Applications Module - Kubernetes Deployments
# This module deploys applications to the EKS cluster using Helm

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.15"
    }
  }
}


# ===================================
# Namespace Reference
# ===================================
# Note: The 'apps' namespace is created by the EKS module
# We just reference it here for the Helm releases

# ===================================
# Application Deployments
# ===================================

# Nginx Sample Application - "By Rnato35"
resource "helm_release" "nginx_sample" {
  name       = "nginx-sample"
  chart      = "${path.module}/charts/nginx-sample"
  namespace  = "apps"
  version    = "1.0.0"

  # Environment-specific values
  values = [
    file("${path.module}/charts/nginx-sample/values.yaml"),
    file("${path.module}/values/${var.environment}/nginx-sample.yaml")
  ]

  # Dynamic values set via Terraform
  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "environment"
      value = var.environment
    },
    {
      name  = "ingress.hosts[0].host"
      value = var.nginx_sample.domain_name
    },
    {
      name  = "ingress.tls[0].hosts[0]"
      value = var.nginx_sample.domain_name
    },
    {
      name  = "ingress.aws.certificateArn"
      value = var.nginx_sample.certificate_arn
    }
  ]

  # Note: Depends on 'apps' namespace created by EKS module
}

