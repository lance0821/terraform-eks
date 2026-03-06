# Fluent Bit starter (log aggregation)

This starter pairs with `kube-prometheus-stack` by adding cluster log shipping via `aws-for-fluent-bit`.

## What this provides

- Helm release pattern for Fluent Bit with IRSA (configured in `infra/terraform.tfvars` under `helm_releases.fluent_bit`).
- CloudWatch Logs starter values in `values-cloudwatch.yaml`.
- S3 starter values in `values-s3.yaml`.
- OpenSearch starter values in `values-opensearch.yaml`.
- Least-privilege IAM policy templates in `policies/`.

## Enable Fluent Bit via Terraform

1. In `infra/terraform.tfvars`, set `helm_releases.fluent_bit.create = true`.
2. Keep `enable_fluent_bit_cloudwatch_policy = true` so Terraform creates and manages the CloudWatch Logs write policy.
3. Set `fluent_bit_cloudwatch_log_group_name` if you want a custom log group (default: `/aws/eks/<project>-<environment>/cluster`).
4. Add extra destination-specific policy ARNs to `helm_releases.fluent_bit.irsa_policy_arns` only when needed (for example S3/OpenSearch).
5. Apply:

```bash
mise run tf:apply
```

## IAM policy templates

Starter templates are provided under `examples/fluent-bit/policies/`:

- `cloudwatch-logs-write-policy.json`
- `s3-write-policy.json`
- `opensearch-write-policy.json`

CloudWatch policy creation is now Terraform-managed in `infra/iam.tf` and automatically injected into `helm_releases.fluent_bit.irsa_policy_arns`.

Use `s3-write-policy.json` and `opensearch-write-policy.json` as policy templates when you need additional destination-specific IAM policies, then add those ARNs under `helm_releases.fluent_bit.irsa_policy_arns`.

Example:

```hcl
irsa_policy_arns = {
	s3_write = "arn:aws:iam::<ACCOUNT_ID>:policy/FluentBitS3Write"
}
```

## Destination starters

CloudWatch Logs:

Use `values-cloudwatch.yaml` fields in `helm_releases.fluent_bit.values` (or keep the inline defaults).

Minimum IAM actions for CloudWatch logs output usually include:

- `logs:CreateLogGroup`
- `logs:CreateLogStream`
- `logs:DescribeLogStreams`
- `logs:PutLogEvents`

S3:

Use `values-s3.yaml` and grant least-privilege write access to the target bucket/prefix.

Minimum IAM actions for S3 output usually include:

- `s3:PutObject`
- `s3:AbortMultipartUpload`
- `s3:ListBucket` (scope to needed prefix)

OpenSearch:

Use `values-opensearch.yaml` and grant least-privilege signed HTTP access to the target domain/index path.

Minimum IAM actions for OpenSearch output usually include:

- `es:ESHttpPost`
- `es:ESHttpPut`
- `es:ESHttpGet` (for template/index checks)

## Wiring values into Terraform

Set `helm_releases.fluent_bit.values` in `infra/terraform.tfvars` to the destination configuration you want.

Example (CloudWatch inline):

```hcl
values = [
	<<-EOT
	serviceAccount:
		create: true
		name: fluent-bit

	cloudWatch:
		enabled: true
		region: us-east-1
		logGroupName: /aws/eks/terraform-eks/cluster
		logStreamPrefix: fluent-bit-
	EOT
]
```
