# Namespace Management
# This file contains reusable namespace configurations with proper RBAC bindings

# ===================================
# Managed Namespaces
# ===================================

# Create namespaces with proper labels and annotations
resource "kubernetes_namespace_v1" "managed_namespaces" {
  for_each   = var.managed_namespaces
  depends_on = [aws_eks_cluster.this, aws_eks_addon.coredns]

  metadata {
    name = each.key

    labels = merge(
      {
        name                        = each.key
        "app.kubernetes.io/name"    = each.key
        "app.kubernetes.io/part-of" = var.name
        "kubernetes.io/managed-by"  = "terraform"
      },
      each.value.labels
    )

    annotations = merge(
      {
        "terraform.io/managed" = "true"
      },
      each.value.annotations
    )
  }

  # Wait for essential cluster components
  timeouts {
    delete = "2m"  # Reduced timeout to fail faster
  }

  # Lifecycle to handle namespace cleanup issues
  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

# Namespace cleanup resource to handle stuck namespaces during destroy
resource "null_resource" "namespace_cleanup" {
  for_each = var.managed_namespaces

  triggers = {
    cluster_name = var.name
    namespace    = each.key
    region       = data.aws_region.current.region
  }

  depends_on = [
    kubernetes_namespace_v1.managed_namespaces
  ]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      # Update kubeconfig
      aws eks update-kubeconfig --name ${self.triggers.cluster_name} --region ${self.triggers.region} || true
      
      # Remove finalizers from AWS Load Balancer Controller resources first
      echo "Removing finalizers from AWS Load Balancer Controller resources in ${self.triggers.namespace}..."
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
      
      # Force delete all resources in the namespace
      echo "Cleaning up namespace ${self.triggers.namespace}..."
      kubectl delete all --all -n ${self.triggers.namespace} --timeout=60s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete ingress --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete targetgroupbindings --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete secrets --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete configmaps --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      kubectl delete persistentvolumeclaims --all -n ${self.triggers.namespace} --timeout=30s --ignore-not-found=true --force --grace-period=0 || true
      
      # Wait a moment for finalizers to complete
      sleep 15
      
      # If namespace is stuck in Terminating, remove finalizers
      if kubectl get namespace ${self.triggers.namespace} 2>/dev/null | grep -q "Terminating"; then
        echo "Namespace ${self.triggers.namespace} stuck in Terminating state, removing finalizers..."
        kubectl patch namespace ${self.triggers.namespace} -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        
        # Force delete the namespace
        kubectl delete namespace ${self.triggers.namespace} --force --grace-period=0 || true
      fi
    EOF

    on_failure = continue
  }

  lifecycle {
    create_before_destroy = false
  }
}

# ===================================
# Namespace-specific RoleBindings
# ===================================

# Bind developers to apps namespace with environment-aware permissions
# Dev environment: developers get read/write access to apps namespace only
resource "kubernetes_role_binding_v1" "developers_namespace_access_write" {
  for_each = var.enable_rbac && var.environment == "dev" ? {
    for ns_name, ns_config in var.managed_namespaces : ns_name => ns_config
    if ns_name == "apps" # Only bind to apps namespace in dev
  } : {}

  depends_on = [
    kubernetes_namespace_v1.managed_namespaces,
    kubernetes_cluster_role_v1.developers_readwrite
  ]

  metadata {
    name      = "developers-write-access"
    namespace = each.key
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "eks:developers-readwrite"
  }

  subject {
    kind = "Group"
    name = "eks:developers"
  }
}

# Bind developers to read-only access in staging/prod environments (apps namespace only)
resource "kubernetes_role_binding_v1" "developers_namespace_access_read" {
  for_each = var.enable_rbac && (var.environment == "staging" || var.environment == "prod") ? {
    for ns_name, ns_config in var.managed_namespaces : ns_name => ns_config
    if ns_name == "apps" # Only bind to apps namespace in staging/prod
  } : {}

  depends_on = [
    kubernetes_namespace_v1.managed_namespaces,
    kubernetes_cluster_role_v1.developers_readonly
  ]

  metadata {
    name      = "developers-read-access"
    namespace = each.key
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "eks:developers-readonly"
  }

  subject {
    kind = "Group"
    name = "eks:developers"
  }
}

# Bind viewers to all namespaces (they have cluster-wide read access already)
# But create namespace-specific bindings for clarity
resource "kubernetes_role_binding_v1" "viewers_namespace_access" {
  for_each = var.enable_rbac ? var.managed_namespaces : {}

  depends_on = [
    kubernetes_namespace_v1.managed_namespaces,
    kubernetes_cluster_role_v1.viewers
  ]

  metadata {
    name      = "viewers-access"
    namespace = each.key
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view" # Use built-in view role for namespace-specific access
  }

  subject {
    kind = "Group"
    name = "eks:viewers"
  }
}



# ===================================
# Network Policies (Optional)
# ===================================

# Create default network policies for isolation if enabled
resource "kubernetes_network_policy_v1" "default_deny_all" {
  for_each = var.enable_network_policies ? var.managed_namespaces : {}

  depends_on = [kubernetes_namespace_v1.managed_namespaces]

  metadata {
    name      = "default-deny-all"
    namespace = each.key
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# Allow ingress from same namespace
resource "kubernetes_network_policy_v1" "allow_same_namespace" {
  for_each = var.enable_network_policies ? var.managed_namespaces : {}

  depends_on = [kubernetes_namespace_v1.managed_namespaces]

  metadata {
    name      = "allow-same-namespace"
    namespace = each.key
  }

  spec {
    pod_selector {}

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = each.key
          }
        }
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            name = each.key
          }
        }
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}