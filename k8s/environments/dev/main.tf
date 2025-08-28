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

# Data sources to get EKS cluster info
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# Providers configuration
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Observability test application
resource "helm_release" "observability_test" {
  name       = "observability-test"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = "18.2.4"
  namespace  = "apps"

  # Base values from app directory
  values = [
    file("${path.module}/../../apps/observability-test/values.yaml"),
    file("${path.module}/values.yaml")
  ]

  # Additional values as YAML
  set = [
    {
      name  = "image.tag"
      value = "1.27.3-alpine"
    },
    {
      name  = "metrics.enabled"
      value = "true"
    }
  ]

  depends_on = [kubernetes_namespace.apps]
}

# Create apps namespace
resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
    labels = {
      environment = "dev"
      managed-by  = "terraform"
    }
  }
}