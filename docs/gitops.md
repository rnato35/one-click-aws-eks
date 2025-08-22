# GitOps: Multi-Environment Terraform via GitHub Actions

This repo is configured for GitOps with separate workflows for infrastructure and applications across three environments: dev, staging, prod.

## Branch Strategy

### Infrastructure Deployment
- **Branches**: `env/dev`, `env/staging`, `env/prod`
- **Triggers**: Changes to `infra/envs/**`, `modules/**`
- **Workflow**: `.github/workflows/terraform.yaml`

### Application Deployment  
- **Branches**: `apps/dev`, `apps/staging`, `apps/prod`
- **Triggers**: Changes to `k8s/**`
- **Workflow**: `.github/workflows/applications.yaml`

## Workflow Behavior
- **Pull requests** run `terraform plan` for visibility
- **Merges** to environment branches run `terraform apply`
- **Manual triggers** available for dev environment deployments
- **Authentication** uses GitHub OIDC to assume AWS IAM Role; no long-lived secrets

## Required setup

1. AWS IAM Role for OIDC
   - Create an IAM Role with a trust policy for GitHub OIDC (issuer: `token.actions.githubusercontent.com`).
   - Allow `sts:AssumeRoleWithWebIdentity` with conditions for:
     - Your org/repo (`repo:<owner>/<repo>:*`) or explicitly limit by branches.
   - Attach a policy with least privileges for your infrastructure and state bucket/table.
   - Store the role ARN as a GitHub secret in each Environment:
     - Environments: dev, staging, prod
     - Secret name: `AWS_ROLE_ARN`

2. Backend variables as repository-level Variables (`Settings > Secrets and variables > Actions > Variables`):
   - `TF_BACKEND_BUCKET` — S3 bucket name
   - `TF_BACKEND_REGION` — Region
   - `TF_BACKEND_DDB_TABLE` — DynamoDB lock table name
   - `TF_BACKEND_KMS_KEY_ID` — KMS key ARN or alias

3. GitHub Environments
   - Create environments: dev, staging, prod.
   - Optionally add reviewers to require approvals before apply.
   - Add the secret `AWS_ROLE_ARN` in each environment.

## Workflow

### Infrastructure Workflow (`terraform.yaml`)
- **PRs to `env/*`**: Run `terraform plan` for infrastructure changes
- **Push to `env/*`**: Run `terraform apply` for infrastructure deployment
- **Manual triggers**: Available for all environments (dev, staging, prod)

### Applications Workflow (`applications.yaml`)  
- **PRs to `apps/*`**: Run `terraform plan` for application changes
- **Push to `apps/*`**: Run `terraform apply` for application deployment
- **Manual triggers**: Available for all environments with plan/apply options
- **Dependencies**: Requires EKS cluster to be deployed first

### State File Organization
- **Infrastructure**: `global/terraform.tfstate` (with workspaces)
- **Applications**: `k8s/{environment}/terraform.tfstate` (separate states per environment)

## Local usage

- Bootstrap the backend (`infra/bootstrap`) if not already created; it will generate `infra/backend.generated.hcl` which is gitignored.
- Initialize root: `terraform init -backend-config=../backend.generated.hcl` or rely on workflow variables.
- Use workspaces or per-env tfvars in `infra/envs/<env>/terraform.tfvars`.

## Notes

- Do not commit real backend config. Use the example file or workflow variables.
- Prefer least-privilege policies for the OIDC role (S3/DynamoDB access to state, KMS usage, and what your infra needs).
