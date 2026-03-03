# Architecture

## Module dependency diagram

## Layer responsibilities

| Layer | Responsibility | Allowed dependencies |
|-------|---------------|---------------------|
| `modules/vpc` | Network: VPC, subnets, NAT, IGW | None |
| `modules/eks` | Control plane: cluster, node groups, addons, IRSA OIDC | None |
| `modules/efs` | Storage: EFS filesystem, security group, mount targets | None |
| `modules/helm-release` | Primitive: single Helm chart deploy with optional IRSA | None |
| `modules/eks-addons` | Composition: opinionated addons + generic passthrough | `helm-release` |
| `infra/` | Orchestration: wires modules, manages cross-cutting IAM | All modules |

## Data flow

1. `vpc` creates network → outputs `vpc_id`, `private_subnets`, `public_subnets`
2. `eks` creates cluster in VPC → outputs `cluster_name`, `endpoint`, `oidc_provider_arn`, `node_security_group_id`
3. `efs` creates filesystem with node SG access (optional)
4. `iam.tf` creates EBS CSI IRSA role + Fluent Bit policy using EKS OIDC
5. `eks-addons` deploys Helm charts using cluster endpoint + OIDC
6. Providers read `cluster_endpoint` + `cluster_certificate_authority_data` from state (not live API)

## IRSA auto-injection

The `helm-release` module automatically injects:
- `serviceAccount.create = true`
- `serviceAccount.name = <irsa_service_account_name>`
- `serviceAccount.annotations.eks.amazonaws.com/role-arn = <IRSA role ARN>`

Via configurable `irsa_annotation_key` to handle charts with different SA paths.
Caller-provided `set` values are appended last (last-wins merge).
