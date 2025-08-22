# GitOps Branch Structure

This repository follows a GitOps approach with separate branch hierarchies for infrastructure and applications.

## Branch Naming Convention

### Infrastructure Branches
- `env/dev` - Development infrastructure
- `env/staging` - Staging infrastructure  
- `env/prod` - Production infrastructure

### Application Branches
- `apps/dev` - Development applications
- `apps/staging` - Staging applications
- `apps/prod` - Production applications

## Initial Setup Commands

After cloning the repository, create the GitOps branches:

```bash
# Create infrastructure branches (if not already created)
git checkout -b env/dev
git push -u origin env/dev

git checkout -b env/staging  
git push -u origin env/staging

git checkout -b env/prod
git push -u origin env/prod

# Create application branches
git checkout main
git checkout -b apps/dev
git push -u origin apps/dev

git checkout main
git checkout -b apps/staging
git push -u origin apps/staging

git checkout main  
git checkout -b apps/prod
git push -u origin apps/prod
```

## Workflow Triggers

### Infrastructure Changes (`terraform.yaml`)
- **Paths**: `infra/envs/**`, `modules/**`, `.github/workflows/terraform.yaml`
- **Branches**: `env/dev`, `env/staging`, `env/prod`

### Application Changes (`applications.yaml`)
- **Paths**: `k8s/**`, `.github/workflows/applications.yaml`  
- **Branches**: `apps/dev`, `apps/staging`, `apps/prod`

## Deployment Process

### Infrastructure Deployment
1. Make changes to `infra/` or `modules/`
2. Create PR against `env/dev` → triggers plan
3. Merge PR → triggers apply to dev
4. Promote to staging/prod as needed

### Application Deployment  
1. Make changes to `k8s/`
2. Create PR against `apps/dev` → triggers plan
3. Merge PR → triggers apply to dev
4. Promote to staging/prod as needed

## Branch Protection (Recommended)

Configure these branch protection rules in GitHub:

- **Require pull request reviews** before merging
- **Require status checks** to pass (terraform plan)
- **Require branches to be up to date** before merging
- **Restrict pushes** to protect production branches