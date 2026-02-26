# Helm release module

Deploy a Helm chart with optional IRSA role creation and automatic service-account role annotation.

## Purpose

This module standardizes Helm deployment behavior in this repository by:
- exposing common `helm_release` lifecycle flags,
- supporting structured `set` and `set_sensitive` inputs,
- optionally creating IRSA and auto-injecting the IAM role ARN into chart values.

## Requirements

- Terraform `>= 1.12.0, < 2.0.0`
- Providers:
  - `hashicorp/helm ~> 3.1`
  - `hashicorp/aws ~> 6.34.0`

## Usage

```hcl
module "metrics_server" {
  source = "../modules/helm-release"

  create         = true
  name           = "metrics-server"
  repository     = "https://kubernetes-sigs.github.io/metrics-server"
  chart          = "metrics-server"
  chart_version  = "3.13.0"
  namespace      = "kube-system"
  values         = []

  tags = {
    Project = "terraform-eks"
    Env     = "dev"
  }
}
```

### IRSA-enabled usage

```hcl
module "external_dns" {
  source = "../modules/helm-release"

  create            = true
  name              = "external-dns"
  repository        = "https://kubernetes-sigs.github.io/external-dns"
  chart             = "external-dns"
  chart_version     = "1.20.0"
  namespace         = "kube-system"

  create_irsa_role          = true
  irsa_role_name_prefix     = "cluster-external-dns"
  irsa_service_account_name = "external-dns"
  irsa_annotation_key       = "serviceAccount"
  oidc_provider_arn         = module.eks.oidc_provider_arn
  irsa_attach_external_dns_policy = true
}
```

## Inputs

### Core release settings

| Name | Type | Default | Description |
|---|---|---:|---|
| `create` | `bool` | `true` | Controls whether resources are created. |
| `name` | `string` | n/a | Release name. |
| `repository` | `string` | `null` | Helm chart repository URL. |
| `chart` | `string` | n/a | Chart name or path. |
| `chart_version` | `string` | `null` | Chart version; if unset, latest is installed. |
| `namespace` | `string` | `kube-system` | Namespace for release. |
| `create_namespace` | `bool` | `false` | Create namespace if it does not exist. |
| `description` | `string` | `null` | Helm release description. |
| `values` | `list(string)` | `[]` | YAML value documents passed to Helm. |
| `set` | `list(object)` | `[]` | Value objects (`name`, `value`, optional `type`). |
| `set_sensitive` | `list(object)` | `[]` | Sensitive value objects masked in plans. |

### Lifecycle and behavior

| Name | Type | Default | Description |
|---|---|---:|---|
| `timeout` | `number` | `300` | Timeout (seconds) for Helm operations. |
| `atomic` | `bool` | `false` | Purge release on failure. |
| `cleanup_on_fail` | `bool` | `false` | Delete new resources on failed upgrade. |
| `wait` | `bool` | `true` | Wait for resources to be ready. |
| `wait_for_jobs` | `bool` | `false` | Wait for all Jobs to complete. |
| `force_update` | `bool` | `false` | Force update through delete/recreate. |
| `recreate_pods` | `bool` | `false` | Restart pods on upgrade/rollback. |
| `max_history` | `number` | `5` | Max retained release history (`0` = unlimited). |
| `dependency_update` | `bool` | `false` | Run `helm dependency update` before install. |
| `replace` | `bool` | `false` | Re-use name if it is a deleted release. |
| `reset_values` | `bool` | `false` | Reset chart values to defaults on upgrade. |
| `reuse_values` | `bool` | `false` | Reuse last release values on upgrade. |
| `skip_crds` | `bool` | `false` | Skip installing CRDs. |
| `lint` | `bool` | `false` | Run `helm lint` before install. |
| `disable_webhooks` | `bool` | `false` | Disable pre/post upgrade hooks. |

### IRSA controls

| Name | Type | Default | Description |
|---|---|---:|---|
| `create_irsa_role` | `bool` | `false` | Create IAM role for Kubernetes service account. |
| `irsa_role_name_prefix` | `string` | `""` | Prefix used for IRSA role name. |
| `irsa_annotation_key` | `string` | `serviceAccount` | Helm value path prefix for service account fields. |
| `irsa_service_account_name` | `string` | `""` | Service account name bound to IAM role. |
| `oidc_provider_arn` | `string` | `""` | OIDC provider ARN for IRSA. |
| `irsa_policy_arns` | `map(string)` | `{}` | Additional policy ARNs attached to IRSA role. |
| `irsa_attach_load_balancer_controller_policy` | `bool` | `false` | Attach managed ALB controller policy. |
| `irsa_attach_external_dns_policy` | `bool` | `false` | Attach managed ExternalDNS policy. |
| `irsa_attach_cert_manager_policy` | `bool` | `false` | Attach managed cert-manager policy. |
| `irsa_attach_ebs_csi_policy` | `bool` | `false` | Attach managed EBS CSI policy. |
| `irsa_attach_efs_csi_policy` | `bool` | `false` | Attach managed EFS CSI policy. |
| `tags` | `map(string)` | `{}` | Tags applied to IAM resources. |

## IRSA annotation behavior

When `create_irsa_role = true`, the module auto-injects these Helm `set` values:
- `<irsa_annotation_key>.create = true`
- `<irsa_annotation_key>.name = <irsa_service_account_name>`
- `<irsa_annotation_key>.annotations.eks.amazonaws.com/role-arn = <generated role ARN>`

Caller-provided `set` entries are appended last and therefore can override defaults if needed.

## Outputs

| Name | Description |
|---|---|
| `release_name` | Helm release name. |
| `release_namespace` | Helm release namespace. |
| `release_status` | Helm release status. |
| `release_version` | Chart version deployed. |
| `release_metadata` | Helm release metadata block. |
| `irsa_role_arn` | IRSA IAM role ARN (if created). |
| `irsa_role_name` | IRSA IAM role name (if created). |
