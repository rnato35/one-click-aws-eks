env_name = "dev"
region   = "us-east-1"

# Networking
vpc_cidr = "10.0.0.0/16"
az_count = 2

# Features
enable_nat_gateway = true
single_nat_gateway = true
enable_flow_logs   = false
enable_nacls       = false

# EKS
enable_eks                              = true
eks_cluster_version                     = "1.28"
eks_enable_cluster_log_types            = ["api", "audit"]
eks_log_retention_in_days               = 7
eks_enable_aws_load_balancer_controller = true
