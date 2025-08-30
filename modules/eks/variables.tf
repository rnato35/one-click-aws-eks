variable "name" {
  description = "Name prefix for EKS cluster and associated resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS cluster"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for load balancers"
  type        = list(string)
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "enable_cluster_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_in_days" {
  description = "Number of days to retain cluster logs"
  type        = number
  default     = 7
}

variable "fargate_profiles" {
  description = "Map of Fargate profile configurations"
  type = map(object({
    namespace = string
    labels    = map(string)
  }))
  default = {
    default = {
      namespace = "default"
      labels    = {}
    }
    kube-system = {
      namespace = "kube-system"
      labels    = {}
    }
    apps = {
      namespace = "apps"
      labels    = {}
    }
  }
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "vpc_cni_addon_version" {
  description = "Version of the VPC CNI addon"
  type        = string
  default     = null
}

variable "coredns_addon_version" {
  description = "Version of the CoreDNS addon"
  type        = string
  default     = null
}

variable "kube_proxy_addon_version" {
  description = "Version of the kube-proxy addon"
  type        = string
  default     = null
}

variable "enable_irsa_for_vpc_cni" {
  description = "Enable IRSA (IAM Roles for Service Accounts) for VPC CNI"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ===================================
# RBAC Configuration Variables
# ===================================

variable "enable_rbac" {
  description = "Enable RBAC configuration with tiered IAM roles and Kubernetes RBAC"
  type        = bool
  default     = true
}

variable "cluster_admin_arns" {
  description = "List of IAM user/role ARNs that can assume the cluster admin role"
  type        = list(string)
  default     = []
}

variable "developer_arns" {
  description = "List of IAM user/role ARNs that can assume the developer role"
  type        = list(string)
  default     = []
}

variable "viewer_arns" {
  description = "List of IAM user/role ARNs that can assume the viewer role"
  type        = list(string)
  default     = []
}

variable "require_mfa" {
  description = "Require MFA for assuming IAM roles (recommended for production)"
  type        = bool
  default     = false
}

variable "additional_user_mappings" {
  description = "Additional IAM user mappings for aws-auth ConfigMap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

# ===================================
# Namespace Management Variables
# ===================================

variable "managed_namespaces" {
  description = "Map of managed namespaces with access configuration"
  type = map(object({
    labels = optional(map(string), {})
    annotations = optional(map(string), {})
    developer_access = optional(list(string), [])
  }))
  default = {
    apps = {
      labels = {
        "app.kubernetes.io/environment" = "development"
        "app.kubernetes.io/tier"        = "application"
      }
      annotations = {
        "description" = "Main application namespace for developers"
      }
      developer_access = ["write"]
    }
  }
}

variable "enable_network_policies" {
  description = "Enable default network policies for namespace isolation"
  type        = bool
  default     = false
}