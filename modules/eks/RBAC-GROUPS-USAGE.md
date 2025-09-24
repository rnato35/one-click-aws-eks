# EKS RBAC with IAM Groups

## Overview

The EKS module now uses IAM Groups for RBAC instead of individual IAM Users. This provides better scalability and management of user permissions.

## IAM Groups Created

### 1. DevOps Group (`{cluster-name}-eks-devops`)
- **Purpose**: Full admin access to all environments
- **Path**: `/eks/`
- **Permissions**: Can assume the cluster admin role
- **MFA**: Required (configurable via `require_mfa` variable)
- **Access**: Full cluster admin (`system:masters`)

### 2. Developers Group (`{cluster-name}-eks-developers`)
- **Purpose**: Environment-specific access
- **Path**: `/eks/`
- **Permissions**: Can assume the developer role
- **MFA**: Required for staging/prod (configurable via `require_mfa` variable)
- **Access**: 
  - **Dev environment**: Read/Write access to `apps` namespace only
  - **Staging/Prod environments**: Read-only access to `apps` namespace only

### 3. Viewers Group (`{cluster-name}-eks-viewers`)
- **Purpose**: Read-only monitoring access
- **Path**: `/eks/`
- **Permissions**: Can assume the viewer role
- **MFA**: Not required
- **Access**: Read-only cluster-wide access

## Environment-Specific Permissions

| Role | Dev Environment | Staging Environment | Production Environment |
|------|-----------------|---------------------|------------------------|
| DevOps | Full Admin | Full Admin | Full Admin |
| Developers | Read/Write `apps` namespace | Read-only `apps` namespace | Read-only `apps` namespace |
| Viewers | Read-only cluster-wide | Read-only cluster-wide | Read-only cluster-wide |

## How It Works

### Architecture
1. **IAM Roles**: Trust policies allow any authenticated principal in the AWS account
2. **IAM Groups**: Have policies that allow assuming the specific EKS roles  
3. **Users**: Get permissions by being added to groups, then can assume roles
4. **EKS Access**: Users assume roles to get kubectl access

### User Management

Users should be added to the appropriate IAM Groups outside of Terraform (via AWS Console, CLI, or separate IAM management):

```bash
# Add user to DevOps group (gets full admin access)
aws iam add-user-to-group --group-name {cluster-name}-eks-devops --user-name {username}

# Add user to Developers group (gets env-specific access)
aws iam add-user-to-group --group-name {cluster-name}-eks-developers --user-name {username}

# Add user to Viewers group (gets read-only access)
aws iam add-user-to-group --group-name {cluster-name}-eks-viewers --user-name {username}
```

### Removing Users from Groups

```bash
# Remove user from group
aws iam remove-user-from-group --group-name {cluster-name}-eks-devops --user-name {username}
```

## Accessing EKS Clusters

Users need to assume the appropriate IAM role to access EKS:

### For DevOps Users:
```bash
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT-ID:role/{cluster-name}-eks-cluster-admins \
  --role-session-name eks-admin-session
```

### For Developers:
```bash
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT-ID:role/{cluster-name}-eks-developers \
  --role-session-name eks-dev-session
```

### For Viewers:
```bash
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT-ID:role/{cluster-name}-eks-viewers \
  --role-session-name eks-viewer-session
```

## Configuration Changes

**IAM User ARN variables have been completely removed from the module.**

The EKS module now exclusively uses IAM Groups for RBAC. The following variables no longer exist:
- ~~`eks_cluster_admin_arns`~~ (removed)
- ~~`eks_developer_arns`~~ (removed)
- ~~`eks_viewer_arns`~~ (removed)

IAM Groups are automatically created and configured when `eks_enable_rbac = true`.

## Migration from User ARNs

1. All IAM user ARN variables have been removed from the module
2. IAM Groups are created automatically
3. Users must be added to the appropriate IAM Groups manually (outside of Terraform)
4. IAM roles are now exclusively assumed through group membership

## Security Best Practices

1. **MFA Requirements**: Enable `eks_require_mfa = true` for staging and production
2. **Least Privilege**: Users get minimal required access for their environment
3. **Namespace Isolation**: Developers only have access to the `apps` namespace
4. **Audit Trail**: All EKS access is logged through CloudTrail with the assumed role information

## Outputs

The module provides outputs for the created IAM Groups:

- `iam_group_eks_devops_name`
- `iam_group_eks_devops_arn`
- `iam_group_eks_developers_name`
- `iam_group_eks_developers_arn`
- `iam_group_eks_viewers_name`
- `iam_group_eks_viewers_arn`