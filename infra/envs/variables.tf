variable "region" {
  description = "AWS region for providers"
  type        = string
}

variable "aws_profile" {
  description = "AWS profile to use for authentication (leave empty for default profile)"
  type        = string
  default     = ""
}

variable "env_name" {
  description = "Short environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

# Prefix for naming sample resources (sanitized to [a-z0-9-])
variable "project_prefix" {
  description = "Project prefix used in sample resource names"
  type        = string
  default     = "one-click"
}

# Network inputs
variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}
variable "az_count" {
  description = "Number of AZs to use when azs not provided"
  type        = number
  default     = 2
}
variable "azs" {
  description = "Optional list of AZs to use"
  type        = list(string)
  default     = null
}
variable "public_subnet_cidrs" {
  description = "Optional public subnet CIDRs (per AZ)"
  type        = list(string)
  default     = null
}
variable "private_app_subnet_cidrs" {
  description = "Optional private app subnet CIDRs (per AZ)"
  type        = list(string)
  default     = null
}
variable "private_db_subnet_cidrs" {
  description = "Optional private db subnet CIDRs (per AZ)"
  type        = list(string)
  default     = null
}

# Feature flags
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}
variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ"
  type        = bool
  default     = true
}
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}
variable "enable_nacls" {
  description = "Enable Network ACLs"
  type        = bool
  default     = false
}

# EKS variables
variable "enable_eks" {
  description = "Enable EKS cluster deployment"
  type        = bool
  default     = true
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "eks_enable_cluster_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "eks_log_retention_in_days" {
  description = "Number of days to retain EKS cluster logs"
  type        = number
  default     = 7
}

variable "eks_fargate_profiles" {
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

variable "eks_enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "eks_vpc_cni_addon_version" {
  description = "Version of the VPC CNI addon"
  type        = string
  default     = null
}

variable "eks_coredns_addon_version" {
  description = "Version of the CoreDNS addon"
  type        = string
  default     = null
}

variable "eks_kube_proxy_addon_version" {
  description = "Version of the kube-proxy addon"
  type        = string
  default     = null
}

variable "eks_enable_irsa_for_vpc_cni" {
  description = "Enable IRSA (IAM Roles for Service Accounts) for VPC CNI"
  type        = bool
  default     = false
}

# ===================================
# EKS RBAC Configuration
# ===================================

variable "eks_enable_rbac" {
  description = "Enable RBAC configuration with tiered IAM roles"
  type        = bool
  default     = true
}


variable "eks_require_mfa" {
  description = "Require MFA for assuming IAM roles (recommended for production)"
  type        = bool
  default     = false
}

variable "eks_managed_namespaces" {
  description = "Map of managed namespaces with access configuration"
  type = map(object({
    labels           = optional(map(string), {})
    annotations      = optional(map(string), {})
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

variable "eks_enable_network_policies" {
  description = "Enable default network policies for namespace isolation"
  type        = bool
  default     = false
}

# ===================================
# Applications Configuration
# ===================================

variable "enable_applications" {
  description = "Enable deployment of applications to EKS cluster"
  type        = bool
  default     = true
}

# Nginx Sample Application Variables
variable "nginx_sample_enabled" {
  description = "Enable nginx-sample application deployment"
  type        = bool
  default     = true
}

variable "nginx_sample_domain_name" {
  description = "Domain name for nginx-sample application"
  type        = string
  default     = "nginx-sample.local"
}

variable "nginx_sample_certificate_arn" {
  description = "ACM certificate ARN for nginx-sample domain"
  type        = string
  default     = ""
}

variable "nginx_sample_replica_count" {
  description = "Number of replicas for nginx-sample"
  type        = number
  default     = 1
}

variable "nginx_sample_enable_autoscaling" {
  description = "Enable horizontal pod autoscaling for nginx-sample"
  type        = bool
  default     = false
}

variable "nginx_sample_min_replicas" {
  description = "Minimum number of replicas for nginx-sample autoscaling"
  type        = number
  default     = 1
}

variable "nginx_sample_max_replicas" {
  description = "Maximum number of replicas for nginx-sample autoscaling"
  type        = number
  default     = 5
}

variable "nginx_sample_cpu_limit" {
  description = "CPU limit for nginx-sample pods"
  type        = string
  default     = "200m"
}

variable "nginx_sample_memory_limit" {
  description = "Memory limit for nginx-sample pods"
  type        = string
  default     = "256Mi"
}

variable "nginx_sample_cpu_request" {
  description = "CPU request for nginx-sample pods"
  type        = string
  default     = "100m"
}

variable "nginx_sample_memory_request" {
  description = "Memory request for nginx-sample pods"
  type        = string
  default     = "128Mi"
}

