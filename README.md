## terraform-eks

### Prerequisites

- Install mise: https://mise.jdx.dev/getting-started.html

### Codespaces / AWS env setup

After devcontainer changes, run `Codespaces: Rebuild Container` from the Command Palette.

Create local AWS env values (do not commit `.env`):

```bash
cp .env.example .env
```

Set values in `.env` for your account/workspace:

- `AWS_PROFILE`
- `AWS_REGION`
- `TF_STATE_BUCKET`
- `TF_STATE_PREFIX`
- `TF_STATE_ENV`

Authenticate with AWS SSO:

Use device code flow in remote dev containers/Codespaces to avoid localhost callback issues.

```bash
aws configure sso --profile dev --use-device-code
aws sso login --profile dev --use-device-code
aws sts get-caller-identity --profile dev
```

Troubleshooting (Codespaces/dev container):

- If login tries to redirect to `127.0.0.1`, re-run with `--use-device-code`.
- If cached SSO/token data is stale, clear cache and sign in again:

```bash
rm -rf ~/.aws/sso/cache ~/.aws/cli/cache
aws sso login --profile dev --use-device-code
```

- If Terraform reports `No valid credential sources found`, set the profile explicitly and retry:

```bash
export AWS_PROFILE=dev
aws sts get-caller-identity --profile dev
AWS_PROFILE=dev terraform -chdir=infra init -upgrade -backend=false
```

`mise.toml` loads `.env` via `_.file = ".env"`, so tasks pick up `AWS_PROFILE`/`AWS_REGION` automatically.

### One-time shell setup

Add mise activation to bash so tools from `mise.toml` are available in every new terminal:

```bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
source ~/.bashrc
```

### Install and verify tools

From this repository:

```bash
mise install
mise current
terraform version
aws --version
kubectl version --client
```

If `terraform` is still not found, open a new terminal and run:

```bash
source ~/.bashrc
```

### Pre-commit hooks

Install git hooks:

```bash
mise run pre-commit:install
```

This installs a `mise`-backed git hook so commits from VS Code Source Control and terminal both work.

Run hooks manually across all files:

```bash
mise run pre-commit:run
```

Optional: create a local Python virtual environment (ignored by git):

```bash
mise run uv:venv
source .venv/bin/activate
```

### AWS commands

If you have not set up your local AWS environment yet, follow `Codespaces / AWS env setup` above first.

For remote containers/Codespaces, use `--use-device-code` for SSO login and see the troubleshooting note above if auth fails.

For direct AWS CLI/Terraform commands outside `mise run`, prefer an explicit profile (for example `AWS_PROFILE=dev`).

Verify active AWS credentials/profile with the task in `mise.toml`:

```bash
mise run aws:whoami
```

Or run AWS CLI directly through mise without relying on shell activation:

```bash
mise exec aws-cli -- aws --version
mise exec aws-cli -- aws configure
```

### Terraform tasks

Run tasks defined in `mise.toml`:

```bash
mise run terraform:init
mise run terraform:plan
mise run terraform:apply
mise run kubeconfig:update
mise run kubeconfig:whoami
mise run kubeconfig:placement
mise run terraform:destroy
mise run terraform:validate
mise run terraform:validate-ci
mise run terraform:fmt
mise run checkov:scan
mise run checkov:scan-all
mise run check
mise run check:ci
```

If running Terraform directly (outside `mise run`), ensure the SSO profile is explicit:

```bash
AWS_PROFILE=dev terraform -chdir=infra init -upgrade -backend=false
```

Or export once per shell session:

```bash
export AWS_PROFILE=dev
```

### Worker node cost optimization (Spot)

`infra/terraform.tfvars` uses a mixed-capacity node group pattern by default:

- `default`: small On-Demand baseline for core/critical workloads.
- `spot`: diversified Spot node group for cost-efficient scale-out.

The `spot` node group also includes:

- label: `workload_tier=spot`
- taint: `workload-tier=spot:NoSchedule`

This keeps general workloads on On-Demand unless they explicitly opt into Spot scheduling.

Example workload manifest (node selector + toleration):

```bash
kubectl apply -f examples/scheduling/deployment-spot-example.yaml
```

Critical workload example pinned to On-Demand nodes:

```bash
kubectl apply -f examples/scheduling/deployment-ondemand-example.yaml
```

See `examples/scheduling/README.md` for guidance on when to use each pattern and how to verify pod placement.

That guide also includes a one-liner to print pod -> node -> capacity type for quick Spot vs On-Demand verification.

Tune `min_size`, `desired_size`, `max_size`, and `instance_types` in `eks_managed_node_groups` to match your workload and interruption tolerance.

### EKS access entries (team access)

The cluster currently supports creator-admin access, but team access should be managed with EKS access entries instead of editing `aws-auth` directly.

`infra/terraform.tfvars` includes:

- `enable_cluster_creator_admin_permissions` (default `true`)
- `eks_access_entries` (default `{}` with example block)

To grant additional IAM role/user access:

1. Add entries in `eks_access_entries` with `principal_arn` and `policy_associations`.
2. Optionally set `enable_cluster_creator_admin_permissions = false` once team access entries are in place.
3. Apply Terraform:

```bash
mise run terraform:apply
```

Example (`cluster admin` + `namespace read-only`):

```hcl
eks_access_entries = {
	admin_role = {
		principal_arn = "arn:aws:iam::<ACCOUNT_ID>:role/PlatformAdmin"
		policy_associations = {
			admin = {
				policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
				access_scope = {
					type = "cluster"
				}
			}
		}
	}

	readonly_dev_ns = {
		principal_arn = "arn:aws:iam::<ACCOUNT_ID>:role/AppTeamReadOnly"
		policy_associations = {
			view_dev = {
				policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
				access_scope = {
					type       = "namespace"
					namespaces = ["dev"]
				}
			}
		}
	}

	readonly_staging_ns = {
		principal_arn = "arn:aws:iam::<ACCOUNT_ID>:role/AppTeamReadOnly"
		policy_associations = {
			view_staging = {
				policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
				access_scope = {
					type       = "namespace"
					namespaces = ["staging"]
				}
			}
		}
	}
}
```

### External Secrets Operator (AWS Secrets Manager / SSM)

Use `helm_releases` to deploy External Secrets Operator with IRSA.

`infra/terraform.tfvars` includes an `external_secrets` example block (disabled by default with `create=false`).

To enable it:

1. Set `helm_releases.external_secrets.create = true` in `infra/terraform.tfvars`.
2. Set `irsa_policy_arns` to least-privilege custom policy ARNs scoped to only the Secrets Manager secrets and SSM parameter paths ESO should read.
3. Apply Terraform:

```bash
mise run terraform:apply
```

After the chart is installed, create your `ClusterSecretStore` / `SecretStore` and `ExternalSecret` Kubernetes resources to sync values into native Kubernetes `Secret` objects.

If you do **not** have External Secrets Operator installed yet, starter manifests will not reconcile until ESO is deployed.

Starter manifests live under `examples/external-secrets/`:

- Use `ClusterSecretStore` for shared platform stores.
- Use namespace-scoped `SecretStore` for tighter tenant isolation.
- AWS Secrets Manager, AWS SSM Parameter Store, and HashiCorp Vault variants are all included.

Quick starts (after editing placeholders like region/path/URL):

```bash
# AWS Secrets Manager (cluster-scoped)
kubectl apply -f examples/external-secrets/clustersecretstore-aws-secretsmanager.yaml
kubectl apply -f examples/external-secrets/externalsecret-example.yaml

# AWS SSM Parameter Store (namespace-scoped example)
kubectl apply -f examples/external-secrets/secretstore-aws-parameterstore.yaml
kubectl apply -f examples/external-secrets/externalsecret-ssm-secretstore.yaml

# HashiCorp Vault (cluster-scoped example)
kubectl apply -f examples/external-secrets/clustersecretstore-vault.yaml
kubectl apply -f examples/external-secrets/externalsecret-vault-clusterstore-example.yaml
```

For the full matrix of files and usage patterns, see `examples/external-secrets/README.md`.

### Log aggregation (Fluent Bit)

`kube-prometheus-stack` covers metrics/alerts, but not cluster log shipping. Pair it with Fluent Bit.

`infra/terraform.tfvars` includes a `helm_releases.fluent_bit` example (disabled by default with `create=false`) using the AWS `aws-for-fluent-bit` Helm chart and IRSA.

To enable it:

1. Set `helm_releases.fluent_bit.create = true` in `infra/terraform.tfvars`.
2. Set `irsa_policy_arns` to least-privilege custom policy ARNs for your selected destination.
3. Update destination values (CloudWatch shown by default).
4. Apply Terraform:

```bash
mise run terraform:apply
```

Starter values are included in:

- `examples/fluent-bit/values-cloudwatch.yaml`
- `examples/fluent-bit/values-s3.yaml`
- `examples/fluent-bit/values-opensearch.yaml`

IAM policy templates are included in:

- `examples/fluent-bit/policies/cloudwatch-logs-write-policy.json`
- `examples/fluent-bit/policies/s3-write-policy.json`
- `examples/fluent-bit/policies/opensearch-write-policy.json`

You can render/create these policies with:

```bash
./scripts/create-fluent-bit-policy.sh --help
```

For S3/OpenSearch, keep the same Helm + IRSA pattern and replace destination output values plus IAM permissions.

See `examples/fluent-bit/README.md` for full setup notes.

### Persistent storage (EBS + EFS)

EBS and EFS are common EKS storage add-ons for PV/PVC workloads:

- EBS CSI is already enabled via `eks_addons.aws-ebs-csi-driver` in `infra/terraform.tfvars`.
- EFS CSI starter is available via `helm_releases.efs_csi` in `infra/terraform.tfvars` (disabled by default).

To enable EFS CSI:

1. Set `helm_releases.efs_csi.create = true` in `infra/terraform.tfvars`.
2. Enable Terraform-managed EFS infrastructure in `infra/terraform.tfvars` by setting `enable_efs_filesystem = true` (or use an existing EFS filesystem).
3. Apply Terraform:

```bash
mise run terraform:apply
```

StorageClass/PVC starter manifests are included in `examples/storage/`:

- `storageclass-ebs-gp3.yaml` + `pvc-ebs-example.yaml`
- `storageclass-efs.yaml` + `pvc-efs-example.yaml`

For EFS, render/apply `storageclass-efs.yaml` with an explicit filesystem ID:

```bash
EFS_FILE_SYSTEM_ID="$(terraform -chdir=infra output -raw efs_file_system_id)" envsubst < examples/storage/storageclass-efs.yaml | kubectl apply -f -
kubectl apply -f examples/storage/pvc-efs-example.yaml
```

See `examples/storage/README.md` for usage and verification commands.

### Backup / DR (Velero)

Velero provides backup/restore for Kubernetes objects and PV snapshots to AWS, which helps recover from accidental namespace deletion or failed stateful rollouts.

`infra/terraform.tfvars` includes a `helm_releases.velero` example (disabled by default with `create=false`) using Helm + IRSA.

To enable it:

1. Set `helm_releases.velero.create = true` in `infra/terraform.tfvars`.
2. Configure backup bucket/region and snapshot location in Velero values.
3. Set `irsa_policy_arns` to your Velero least-privilege policy ARN.
4. Apply Terraform:

```bash
mise run terraform:apply
```

Starter files are in `examples/velero/`:

- `values-aws-s3-ebs.yaml`
- `schedule-daily.yaml`
- `restore-latest-from-schedule.sh`
- `policies/velero-s3-ebs-snapshots-policy.json`

See `examples/velero/README.md` for setup, policy rendering, and restore workflow.

Template baseline note:

- `infra/main.tf` is intentionally minimal and does not create default AWS infrastructure.
- Add your own resources or internal modules under `infra/` and `modules/`.

Checkov task behavior:

- `checkov:scan` / `checkov:sarif`: blocking scans for owned code (excludes `infra/.external_modules`).
- `checkov:scan-all` / `checkov:sarif-all`: advisory scans including downloaded community module code.

### Security checks policy

- Prefer fixing findings instead of suppressing checks.
- If suppression is required, scope it to specific check IDs and document rationale in the PR.
- Keep suppressions minimal, time-bound, and reviewed regularly.
- Checkov policy is configured in `.checkov.yml`; TFLint policy is configured in `.tflint.hcl`.

### Remote state (S3 backend)

`infra/backend.tf` uses an S3 backend with runtime backend config.

Set these GitHub repository or environment variables before running deploy/destroy workflows:

- `TF_STATE_BUCKET` (required): S3 bucket name for Terraform state.
- `TF_STATE_PREFIX` (optional): Prefix under the bucket. Defaults to GitHub repository name.
- `AWS_ROLE_TO_ASSUME` (required): IAM role ARN for OIDC auth.

For this repository, set `TF_STATE_BUCKET=tfstate-llewandowski`.

Locking is configured with S3 native lockfiles (`use_lockfile=true`), so no DynamoDB table is required.

Bucket requirements (configure on the S3 bucket itself):

- Versioning enabled.
- Default encryption enabled (SSE-S3 or SSE-KMS).

State key path is set by prefix + workflow input environment:

- `<prefix>/dev/terraform.tfstate`
- `<prefix>/staging/terraform.tfstate`
- `<prefix>/prod/terraform.tfstate`

Where `<prefix>` is `TF_STATE_PREFIX` if set, otherwise the GitHub repo name (for example `terraform-eks`).

For local `mise run terraform:init`:

- Init always configures the S3 backend.
- Defaults are set in `mise.toml` (`TF_STATE_BUCKET=tfstate-llewandowski`, `TF_STATE_PREFIX=terraform-labs`, `TF_STATE_ENV=dev`).
- Override `TF_STATE_PREFIX` or `TF_STATE_ENV` per workspace/environment as needed.

### Template bootstrap for new repos

Use the bootstrap script to configure AWS OIDC trust + GitHub environments/variables for a new repository created from this template.

```bash
./scripts/bootstrap-template-repo.sh \
	--repo <owner/new-repo> \
	--aws-profile dev \
	--state-bucket tfstate-llewandowski
```

Defaults:

- Role name: `GitHubActionsTerraformDeploy`
- Region: `us-east-1`
- State prefix: repository name

After bootstrap, run the `Deploy (Terraform Apply)` workflow manually with `environment=dev` and `confirm=APPLY`.

### Re-enable strict TFLint rules

Re-enable these rules in `.tflint.hcl` when the scaffold grows into real infrastructure:

- `terraform_unused_declarations`: re-enable once locals/variables are actively consumed by resources or modules.
- `terraform_unused_required_providers`: re-enable once `required_providers` only lists providers used in code.
- Run `mise run check` after re-enabling to verify no regressions.
