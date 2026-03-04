# VPC module

Provision a VPC baseline using `terraform-aws-modules/vpc/aws` with repository defaults for subnet tagging and NAT behavior.

## Purpose

Use this module to create networking primitives required by the EKS stack:
- VPC
- Public and private subnets
- Optional NAT gateway topology

## Upstream dependency

- Source module: `terraform-aws-modules/vpc/aws`
- Pinned version: `6.6.0` (in `main.tf`)

## Usage

```hcl
module "vpc" {
  source = "../modules/vpc"

  name            = "terraform-eks-dev"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
  public_subnets  = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
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
| `name` | `string` | n/a | Name prefix for VPC resources. |
| `cidr` | `string` | n/a | IPv4 CIDR block for the VPC. |
| `azs` | `list(string)` | n/a | Availability zones to use. |
| `private_subnets` | `list(string)` | n/a | Private subnet CIDR blocks (one per AZ). |
| `public_subnets` | `list(string)` | n/a | Public subnet CIDR blocks (one per AZ). |
| `enable_nat_gateway` | `bool` | `true` | Whether to create NAT gateway resources. |
| `single_nat_gateway` | `bool` | `true` | Whether to create a single shared NAT gateway. |
| `one_nat_gateway_per_az` | `bool` | `false` | Whether to create one NAT gateway per AZ. |
| `private_subnet_tags` | `map(string)` | `{}` | Additional tags for private subnets. |
| `public_subnet_tags` | `map(string)` | `{}` | Additional tags for public subnets. |
| `tags` | `map(string)` | `{}` | Tags applied to all VPC resources. |

## Validation rules

- `cidr` must be a valid IPv4 CIDR block.
- `azs` must contain at least one AZ.
- `private_subnets` and `public_subnets` must each have exactly one CIDR per AZ.
- `single_nat_gateway` and `one_nat_gateway_per_az` cannot both be `true`.

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | ID of the created VPC. |
| `private_subnets` | IDs of created private subnets. |
| `public_subnets` | IDs of created public subnets. |
| `vpc_cidr_block` | CIDR block of the created VPC. |
