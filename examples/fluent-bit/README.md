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
2. Replace `irsa_policy_arns` with least-privilege custom policy ARNs for your destination.
3. Update region/log group values as needed.
4. Apply:

```bash
mise run terraform:apply
```

## IAM policy templates

Starter templates are provided under `examples/fluent-bit/policies/`:

- `cloudwatch-logs-write-policy.json`
- `s3-write-policy.json`
- `opensearch-write-policy.json`

Replace placeholders (`<ACCOUNT_ID>`, `<REGION>`, etc.), create IAM policies in your account, and attach policy ARNs in `helm_releases.fluent_bit.irsa_policy_arns`.

Use helper script to render and create policies:

```bash
# CloudWatch Logs policy
./scripts/create-fluent-bit-policy.sh \
	--template cloudwatch \
	--policy-name FluentBitCloudWatchLogsWrite \
	--region us-east-1 \
	--log-group-name /aws/eks/terraform-eks/cluster

# S3 policy
./scripts/create-fluent-bit-policy.sh \
	--template s3 \
	--policy-name FluentBitS3Write \
	--bucket-name my-eks-logs-bucket \
	--prefix fluent-bit/dev

# OpenSearch policy (render-only)
./scripts/create-fluent-bit-policy.sh \
	--template opensearch \
	--policy-name FluentBitOpenSearchWrite \
	--domain-name my-logs-domain \
	--render-only
```

Template variables are `${REGION}`, `${ACCOUNT_ID}`, `${LOG_GROUP_NAME}`, `${BUCKET_NAME}`, `${PREFIX}`, `${DOMAIN_NAME}`.

Example:

```hcl
irsa_policy_arns = {
	logs_write = "arn:aws:iam::<ACCOUNT_ID>:policy/FluentBitCloudWatchLogsWrite"
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
