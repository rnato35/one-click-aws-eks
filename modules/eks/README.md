# EKS Module

This module creates an Amazon EKS cluster with Fargate profiles and AWS Load Balancer Controller support.

## Features

- EKS cluster with configurable Kubernetes version
- Fargate profiles for serverless pod execution
- Essential EKS add-ons (VPC CNI, CoreDNS, kube-proxy)
- AWS Load Balancer Controller IAM role and policies
- OIDC identity provider for service account authentication
- CloudWatch logging for cluster control plane
- KMS encryption for secrets
- Pre-configured "apps" namespace

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  name               = "my-eks-cluster"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_app_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  cluster_version = "1.28"
  
  fargate_profiles = {
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

  enable_aws_load_balancer_controller = true

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Fargate Profiles

The module creates Fargate profiles for:
- `default` namespace
- `kube-system` namespace (required for CoreDNS)
- `apps` namespace (for application workloads)

## AWS Load Balancer Controller

When enabled, the module creates:
- IAM role for the AWS Load Balancer Controller
- IAM policy with necessary permissions
- OIDC identity provider for service account authentication

To install the AWS Load Balancer Controller, use kubectl or Helm after the cluster is created:

```bash
# Using Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=<aws-region> \
  --set vpcId=<vpc-id>
```

## Outputs

- `cluster_endpoint`: EKS cluster API endpoint
- `cluster_certificate_authority_data`: Certificate authority data for kubectl
- `oidc_provider_arn`: OIDC provider ARN for service account roles
- `aws_load_balancer_controller_role_arn`: IAM role ARN for the Load Balancer Controller