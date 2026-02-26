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
