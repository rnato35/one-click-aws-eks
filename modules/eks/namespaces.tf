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
        name                         = each.key
        "app.kubernetes.io/name"     = each.key
        "app.kubernetes.io/part-of"  = var.name
        "kubernetes.io/managed-by"   = "terraform"
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
    delete = "5m"
  }
}

# ===================================
# Namespace-specific RoleBindings
# ===================================

# Bind developers to specific namespaces
resource "kubernetes_role_binding_v1" "developers_namespace_access" {
  for_each = var.enable_rbac ? {
    for ns_name, ns_config in var.managed_namespaces : ns_name => ns_config
    if contains(ns_config.developer_access, "write")
  } : {}
  
  depends_on = [
    kubernetes_namespace_v1.managed_namespaces,
    kubernetes_cluster_role_v1.developers
  ]

  metadata {
    name      = "developers-access"
    namespace = each.key
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "eks:developers"
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
    name      = "view"  # Use built-in view role for namespace-specific access
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