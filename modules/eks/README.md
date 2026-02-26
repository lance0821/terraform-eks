# EKS module

Create an Amazon EKS control plane and managed node groups using `terraform-aws-modules/eks/aws`.

## Purpose

This module wraps the upstream EKS module with repository defaults and a reduced interface for the root stack.

## Upstream dependency

- Source module: `terraform-aws-modules/eks/aws`
- Pinned version: `21.15.1` (in `main.tf`)

## Requirements

- Terraform `>= 1.12.0, < 2.0.0`

## Usage

```hcl
module "eks" {
  source = "../modules/eks"

  name               = "terraform-eks-dev"
  kubernetes_version = "1.31"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  endpoint_public_access  = true
  endpoint_private_access = true

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  tags = {
    Project = "terraform-eks"
    Env     = "dev"
  }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---:|---|
| `name` | `string` | n/a | EKS cluster name. |
| `kubernetes_version` | `string` | n/a | Kubernetes version for the EKS control plane. |
| `vpc_id` | `string` | n/a | VPC ID where the cluster is deployed. |
| `subnet_ids` | `list(string)` | n/a | Subnet IDs used by the cluster and node groups. |
| `endpoint_public_access` | `bool` | `true` | Whether the API server endpoint is publicly accessible. |
| `endpoint_private_access` | `bool` | `true` | Whether the API server endpoint is privately accessible. |
| `enable_irsa` | `bool` | `true` | Whether to enable IAM Roles for Service Accounts (IRSA). |
| `enable_cluster_creator_admin_permissions` | `bool` | `true` | Whether cluster creator gets admin permissions. |
| `eks_managed_node_groups` | `any` | `{}` | Managed node group definitions passed through to upstream module. |
| `addons` | `any` | `{}` | EKS add-on definitions passed through to upstream module. |
| `tags` | `map(string)` | `{}` | Tags applied to cluster resources. |

## Validation rules

- `name` and `vpc_id` must not be empty.
- `subnet_ids` must include at least one subnet.

## Outputs

| Name | Description |
|---|---|
| `cluster_name` | Name of the EKS cluster. |
| `cluster_arn` | ARN of the EKS cluster. |
| `cluster_endpoint` | Endpoint for the Kubernetes API server. |
| `cluster_version` | Kubernetes version of the cluster. |
| `cluster_security_group_id` | Cluster security group ID. |
| `node_security_group_id` | Shared node security group ID. |
| `oidc_provider_arn` | OIDC provider ARN used for IRSA. |
| `cluster_oidc_issuer_url` | OIDC issuer URL for the cluster. |
