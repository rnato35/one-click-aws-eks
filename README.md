# One-Click AWS Three-Tier Foundation

Reusable Terraform to provision base networking for a 3-tier app: VPC, IGW, NAT, public/private subnets, route tables, optional NACLs and VPC flow logs. No load balancers or security groups.

## Structure
- modules/
	- network: VPC, subnets, routing, optional NACLs and flow logs
- infra/envs: consumable root module wired with variables and simple env tfvars

## Quick start
1. Configure a backend (S3/Dynamo) in `infra/envs/versions.tf` backend block via CLI or `backend.hcl`.
2. Set variables in `infra/envs/dev/terraform.tfvars` (env_name, region, optional feature flags).
3. From `infra/envs`, run init/plan/apply.

Outputs expose subnet IDs and VPC ID to attach compute later.
