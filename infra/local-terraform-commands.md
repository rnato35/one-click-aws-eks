# Local Terraform Commands

This file contains the correct commands to run Terraform locally, ensuring state file compatibility with GitHub Actions.

## Initial Setup

```bash
cd infra/envs

# Initialize Terraform with the backend configuration
terraform init -backend-config="../backend.generated.hcl"

# Create and select the environment workspace (dev/staging/prod)
terraform workspace new dev    # Only needed the first time
terraform workspace select dev
```

## Daily Operations

```bash
# Always ensure you're in the correct workspace
terraform workspace select dev

# Plan (using dev environment as example)
terraform plan -var-file="dev/terraform.tfvars" -var "region=us-east-1"

# Apply
terraform apply -var-file="dev/terraform.tfvars" -var "region=us-east-1"

# Destroy (be careful!)
terraform destroy -var-file="dev/terraform.tfvars" -var "region=us-east-1"
```

## Check Current Workspace

```bash
terraform workspace show
terraform workspace list
```

## State File Locations

With the workspace configuration:
- **Local & GitHub Actions**: `<bucket>/envs/{workspace}/global/terraform.tfstate`
- **dev workspace**: `<bucket>/envs/dev/global/terraform.tfstate`
- **staging workspace**: `<bucket>/envs/staging/global/terraform.tfstate`
- **prod workspace**: `<bucket>/envs/prod/global/terraform.tfstate`

## Important Notes

1. **Always use workspaces locally** - this ensures state file compatibility with GitHub Actions
2. **Check your workspace** before running any Terraform commands with `terraform workspace show`
3. **Use the same tfvars file** as the environment you're working on (dev/staging/prod)