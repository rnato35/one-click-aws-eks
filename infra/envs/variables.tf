variable "region" {
  description = "AWS region for providers"
  type        = string
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
  default     = "1.28"
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
