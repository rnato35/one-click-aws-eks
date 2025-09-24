# Variables for Applications Module

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "nginx_sample" {
  description = "Configuration for nginx-sample application"
  type = object({
    enabled            = bool
    domain_name        = string
    certificate_arn    = string
    replica_count      = number
    enable_autoscaling = bool
    min_replicas       = number
    max_replicas       = number
    cpu_limit          = string
    memory_limit       = string
    cpu_request        = string
    memory_request     = string
  })
  default = {
    enabled            = true
    domain_name        = "nginx-sample.local"
    certificate_arn    = ""
    replica_count      = 1
    enable_autoscaling = false
    min_replicas       = 1
    max_replicas       = 5
    cpu_limit          = "200m"
    memory_limit       = "256Mi"
    cpu_request        = "100m"
    memory_request     = "128Mi"
  }
}

