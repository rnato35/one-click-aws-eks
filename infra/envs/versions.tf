terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.15"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile != "" ? var.aws_profile : null
}

provider "kubernetes" {
  # Configure only when EKS is enabled and cluster exists
  host                   = var.enable_eks ? try(module.eks[0].cluster_endpoint, "https://kubernetes.default.svc") : "https://kubernetes.default.svc"
  cluster_ca_certificate = var.enable_eks ? try(base64decode(module.eks[0].cluster_certificate_authority_data), null) : null
  
  dynamic "exec" {
    # Only configure exec authentication when EKS is enabled
    for_each = var.enable_eks ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", try(module.eks[0].cluster_id, ""), "--profile", var.aws_profile]
    }
  }
  
  # Ignore server certificate verification for dummy configurations
  insecure = !var.enable_eks
}

provider "helm" {
  kubernetes = {
    host                   = var.enable_eks ? try(module.eks[0].cluster_endpoint, "https://kubernetes.default.svc") : "https://kubernetes.default.svc"
    cluster_ca_certificate = var.enable_eks ? try(base64decode(module.eks[0].cluster_certificate_authority_data), null) : null
    
    exec = var.enable_eks ? {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", try(module.eks[0].cluster_id, ""), "--profile", var.aws_profile]
    } : null
    
    insecure = !var.enable_eks
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
