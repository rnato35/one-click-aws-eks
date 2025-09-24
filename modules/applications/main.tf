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
  name      = "nginx-sample"
  chart     = "${path.module}/charts/nginx-sample"
  namespace = "apps"
  version   = "1.0.0"

  # Timeout configurations for better reliability
  timeout         = 300 # 5 minutes for install/upgrade
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = true
  force_update    = true
  replace         = true
  reset_values    = true
  reuse_values    = false
  recreate_pods   = false
  max_history     = 5

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

# Cleanup resource for Application Helm releases during destroy
# This ensures applications are cleaned up before EKS cluster resources
resource "null_resource" "app_cleanup" {
  triggers = {
    cluster_name  = var.cluster_name
    nginx_release = helm_release.nginx_sample.name
    namespace     = helm_release.nginx_sample.namespace
    region        = data.aws_region.current.region
  }

  depends_on = [
    helm_release.nginx_sample
  ]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      # Update kubeconfig
      aws eks update-kubeconfig --name ${self.triggers.cluster_name} --region ${self.triggers.region} || true
      
      # Force delete the specific Helm release
      helm delete ${self.triggers.nginx_release} --namespace ${self.triggers.namespace} --timeout 60s --wait || true
      
      # Remove finalizers from AWS Load Balancer Controller resources first
      echo "Removing finalizers from AWS Load Balancer Controller resources..."
      kubectl get ingress -n ${self.triggers.namespace} -o name 2>/dev/null | while read ingress; do
        if [ -n "$ingress" ]; then
          kubectl patch "$ingress" -n ${self.triggers.namespace} -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        fi
      done
      
      kubectl get targetgroupbindings -n ${self.triggers.namespace} -o name 2>/dev/null | while read tgb; do
        if [ -n "$tgb" ]; then
          kubectl patch "$tgb" -n ${self.triggers.namespace} -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        fi
      done
      
      # Force delete any lingering resources in the namespace
      kubectl delete all --all -n ${self.triggers.namespace} --timeout=60s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete ingress --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete targetgroupbindings --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete svc --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete secrets --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete configmaps --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete persistentvolumeclaims --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      
      # Give some time for finalizers to complete
      sleep 10
      
      # If namespace is still terminating, remove finalizers
      if kubectl get namespace ${self.triggers.namespace} 2>/dev/null | grep -q "Terminating"; then
        echo "Namespace ${self.triggers.namespace} is stuck in Terminating state, removing finalizers..."
        kubectl patch namespace ${self.triggers.namespace} -p '{"metadata":{"finalizers":[]}}' --type=merge || true
      fi
    EOF

    on_failure = continue
  }

  lifecycle {
    create_before_destroy = false
  }
}

# Data source for current AWS region
data "aws_region" "current" {}

