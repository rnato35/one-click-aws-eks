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
  }
  backend "s3" {}
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

provider "kubernetes" {
  host                   = var.enable_eks ? module.eks[0].cluster_endpoint : null
  cluster_ca_certificate = var.enable_eks ? base64decode(module.eks[0].cluster_certificate_authority_data) : null
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.enable_eks ? module.eks[0].cluster_id : "", "--profile", var.aws_profile]
  }
}

provider "helm" {
  kubernetes = {
    host                   = var.enable_eks ? module.eks[0].cluster_endpoint : null
    cluster_ca_certificate = var.enable_eks ? base64decode(module.eks[0].cluster_certificate_authority_data) : null
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.enable_eks ? module.eks[0].cluster_id : "", "--profile", var.aws_profile]
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
