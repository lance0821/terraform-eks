# EKS addons module

Deploy a curated set of EKS add-ons and optional generic Helm releases on top of an existing EKS cluster.

## Purpose

This module composes reusable `../helm-release` modules to install:
- AWS Load Balancer Controller
- Metrics Server
- ExternalDNS
- cert-manager
- kube-prometheus-stack
- Karpenter
- Argo CD
- additional arbitrary Helm releases (`helm_releases`)

## Requirements

- Terraform `>= 1.12.0, < 2.0.0`
- Providers:
  - `hashicorp/helm ~> 3.1`
  - `hashicorp/aws ~> 6.34.0`

## Usage

```hcl
module "eks_addons" {
  source = "../modules/eks-addons"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn
  region            = var.region
  vpc_id            = module.vpc.vpc_id

  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true
  enable_external_dns                 = false
  enable_cert_manager                 = true
  enable_kube_prometheus_stack        = true
  enable_karpenter                    = false
  enable_argocd                       = true

  tags = local.tags
}
```

## Inputs

### Cluster context

| Name | Type | Default | Description |
|---|---|---:|---|
| `cluster_name` | `string` | n/a | EKS cluster name. |
| `cluster_endpoint` | `string` | n/a | EKS cluster endpoint. |
| `region` | `string` | n/a | AWS region. |
| `vpc_id` | `string` | n/a | VPC ID (required by ALB controller). |
| `oidc_provider_arn` | `string` | n/a | OIDC provider ARN for IRSA. |

### Add-on toggles

| Name | Type | Default | Description |
|---|---|---:|---|
| `enable_aws_load_balancer_controller` | `bool` | `true` | Enable AWS Load Balancer Controller. |
| `enable_metrics_server` | `bool` | `true` | Enable metrics-server. |
| `enable_external_dns` | `bool` | `false` | Enable external-dns with Route53. |
| `enable_cert_manager` | `bool` | `false` | Enable cert-manager. |
| `enable_kube_prometheus_stack` | `bool` | `false` | Enable kube-prometheus-stack. |
| `enable_karpenter` | `bool` | `false` | Enable Karpenter. |
| `enable_argocd` | `bool` | `false` | Enable Argo CD. |

### Add-on configuration maps

| Name | Type | Default | Description |
|---|---|---:|---|
| `aws_load_balancer_controller` | `any` | `{}` | Override ALB controller defaults. |
| `metrics_server` | `any` | `{}` | Override metrics-server defaults. |
| `external_dns` | `any` | `{}` | Override external-dns defaults. |
| `cert_manager` | `any` | `{}` | Override cert-manager defaults. |
| `kube_prometheus_stack` | `any` | `{}` | Override kube-prometheus-stack defaults. |
| `karpenter` | `any` | `{}` | Override Karpenter defaults. |
| `argocd` | `any` | `{}` | Override Argo CD defaults. |
| `helm_releases` | `any` | `{}` | Generic Helm releases map. |
| `tags` | `map(string)` | `{}` | Tags applied to addon resources. |

## Built-in chart defaults

| Add-on | Chart | Version | Namespace |
|---|---|---|---|
| AWS Load Balancer Controller | `aws-load-balancer-controller` | `1.14.0` | `kube-system` |
| Metrics Server | `metrics-server` | `3.13.0` | `kube-system` |
| ExternalDNS | `external-dns` | `1.20.0` | `kube-system` |
| cert-manager | `cert-manager` | `v1.17.2` | `cert-manager` |
| kube-prometheus-stack | `kube-prometheus-stack` | `82.4.0` | `monitoring` |
| Karpenter | `karpenter` | `1.4.0` | `karpenter` |
| Argo CD | `argo-cd` | `7.8.13` | `argocd` |

## Operational notes

- The module expects the EKS cluster and OIDC provider to already exist.
- IRSA is enabled for add-ons that require AWS API access (ALB controller, ExternalDNS, cert-manager, Karpenter).
- Karpenter still requires additional infrastructure not created here (for example node IAM/profile and interruption queue). Pass additional policies through `karpenter.irsa_policy_arns`.

## Outputs

### Opinionated add-ons

Each output returns an object with enablement and release metadata.

| Name | Description |
|---|---|
| `aws_load_balancer_controller` | ALB controller output object (`enabled`, `release_name`, `irsa_role_arn`). |
| `metrics_server` | Metrics server output object (`enabled`, `release_name`). |
| `external_dns` | ExternalDNS output object (`enabled`, `release_name`, `irsa_role_arn`). |
| `cert_manager` | cert-manager output object (`enabled`, `release_name`, `irsa_role_arn`). |
| `kube_prometheus_stack` | Prometheus stack output object (`enabled`, `release_name`). |
| `karpenter` | Karpenter output object (`enabled`, `release_name`, `irsa_role_arn`). |
| `argocd` | Argo CD output object (`enabled`, `release_name`). |

### Generic releases

| Name | Description |
|---|---|
| `helm_releases` | Map of generic release outputs keyed by release key (`release_name`, `release_namespace`, `release_status`, `release_version`, `irsa_role_arn`). |
