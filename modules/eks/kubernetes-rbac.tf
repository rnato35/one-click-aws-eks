# Kubernetes RBAC Configuration
# This file contains ClusterRoles, ClusterRoleBindings, and namespace-specific RBAC

# ===================================
# ClusterRoles
# ===================================

# Developers ClusterRole - Read/Write for Dev, Read-only for Staging/Prod
# This ClusterRole defines permissions that will be applied via namespace-scoped RoleBindings
resource "kubernetes_cluster_role_v1" "developers_readwrite" {
  count      = var.enable_rbac ? 1 : 0
  depends_on = [aws_eks_cluster.this]

  metadata {
    name = "eks:developers-readwrite"
  }

  # Full read/write permissions for development environment
  rule {
    api_groups = [""]
    resources = [
      "pods",
      "pods/log",
      "pods/status",
      "services",
      "services/status",
      "endpoints",
      "configmaps",
      "secrets",
      "persistentvolumeclaims"
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete"
    ]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "deployments",
      "deployments/status",
      "replicasets",
      "replicasets/status"
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete"
    ]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources = [
      "ingresses",
      "networkpolicies"
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete"
    ]
  }

  rule {
    api_groups = ["autoscaling"]
    resources = [
      "horizontalpodautoscalers"
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete"
    ]
  }
}

# Developers ClusterRole - Read-only for Staging/Prod environments
resource "kubernetes_cluster_role_v1" "developers_readonly" {
  count      = var.enable_rbac ? 1 : 0
  depends_on = [aws_eks_cluster.this]

  metadata {
    name = "eks:developers-readonly"
  }

  # Read-only permissions for staging/production environments
  rule {
    api_groups = [""]
    resources = [
      "pods",
      "pods/log",
      "pods/status",
      "services",
      "services/status",
      "endpoints",
      "configmaps",
      "persistentvolumeclaims"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "deployments",
      "deployments/status",
      "replicasets",
      "replicasets/status"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources = [
      "ingresses",
      "networkpolicies"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }

  rule {
    api_groups = ["autoscaling"]
    resources = [
      "horizontalpodautoscalers"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }
}

# Viewers ClusterRole - read-only access
resource "kubernetes_cluster_role_v1" "viewers" {
  count      = var.enable_rbac ? 1 : 0
  depends_on = [aws_eks_cluster.this]

  metadata {
    name = "eks:viewers"
  }

  rule {
    api_groups = [""]
    resources = [
      "namespaces",
      "pods",
      "pods/log",
      "pods/status",
      "services",
      "services/status",
      "endpoints",
      "configmaps",
      "persistentvolumeclaims",
      "nodes",
      "events"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "deployments",
      "deployments/status",
      "replicasets",
      "replicasets/status",
      "daemonsets",
      "statefulsets"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources = [
      "ingresses",
      "networkpolicies"
    ]
    verbs = [
      "get",
      "list",
      "watch"
    ]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["*"]
    verbs = [
      "get",
      "list"
    ]
  }
}


# ===================================
# ClusterRoleBindings
# ===================================


resource "kubernetes_cluster_role_binding_v1" "viewers" {
  count      = var.enable_rbac ? 1 : 0
  depends_on = [aws_eks_cluster.this, kubernetes_cluster_role_v1.viewers]

  metadata {
    name = "eks:viewers"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "eks:viewers"
  }

  subject {
    kind = "Group"
    name = "eks:viewers"
  }
}

