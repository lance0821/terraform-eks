#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Bootstrap a new Terraform template-based repository for AWS OIDC deploy workflows.

Required:
  --repo OWNER/REPO            GitHub repository (e.g. lance0821/my-new-repo)

Optional:
  --aws-profile NAME           AWS CLI profile (default: dev)
  --region REGION              AWS region for backend/workflows (default: us-east-1)
  --role-name NAME             IAM role name for GitHub OIDC (default: GitHubActionsTerraformDeploy)
  --state-bucket NAME          S3 backend bucket (default: tfstate-llewandowski)
  --state-prefix PREFIX        State prefix under bucket (default: repo name)
  --attach-admin               Attach AdministratorAccess policy to role (lab default)
  --no-attach-admin            Do not attach AdministratorAccess

Example:
  ./scripts/bootstrap-template-repo.sh \
    --repo lance0821/new-app-infra \
    --aws-profile dev \
    --state-bucket tfstate-llewandowski
EOF
}

REPO=""
AWS_PROFILE_NAME="dev"
AWS_REGION_VALUE="us-east-1"
ROLE_NAME="GitHubActionsTerraformDeploy"
STATE_BUCKET="tfstate-llewandowski"
STATE_PREFIX=""
ATTACH_ADMIN="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="$2"; shift 2 ;;
    --aws-profile)
      AWS_PROFILE_NAME="$2"; shift 2 ;;
    --region)
      AWS_REGION_VALUE="$2"; shift 2 ;;
    --role-name)
      ROLE_NAME="$2"; shift 2 ;;
    --state-bucket)
      STATE_BUCKET="$2"; shift 2 ;;
    --state-prefix)
      STATE_PREFIX="$2"; shift 2 ;;
    --attach-admin)
      ATTACH_ADMIN="true"; shift ;;
    --no-attach-admin)
      ATTACH_ADMIN="false"; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1 ;;
  esac
done

if [[ -z "$REPO" ]]; then
  echo "--repo is required" >&2
  usage
  exit 1
fi

if [[ -z "$STATE_PREFIX" ]]; then
  STATE_PREFIX="${REPO#*/}"
fi

export AWS_PROFILE="$AWS_PROFILE_NAME"
export AWS_REGION="$AWS_REGION_VALUE"
export AWS_DEFAULT_REGION="$AWS_REGION_VALUE"
export AWS_PAGER=""
export GH_PAGER=cat

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

echo "==> AWS account: ${ACCOUNT_ID}"
echo "==> Repo: ${REPO}"
echo "==> Role ARN: ${ROLE_ARN}"
echo "==> State bucket/prefix: ${STATE_BUCKET}/${STATE_PREFIX}"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" >/dev/null 2>&1; then
  echo "==> OIDC provider exists"
else
  echo "==> Creating OIDC provider"
  aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 >/dev/null
fi

TRUST_POLICY=$(cat <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:repository": "${REPO}"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:${REPO}:environment:dev",
            "repo:${REPO}:environment:staging",
            "repo:${REPO}:environment:prod"
          ]
        }
      }
    }
  ]
}
JSON
)

echo "==> Creating/updating IAM role trust policy"
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document "$TRUST_POLICY" >/dev/null
else
  aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "$TRUST_POLICY" >/dev/null
fi

if [[ "$ATTACH_ADMIN" == "true" ]]; then
  echo "==> Ensuring AdministratorAccess is attached (lab default)"
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess >/dev/null
fi

echo "==> Configuring GitHub environments"
for env_name in dev staging prod; do
  gh api --method PUT "/repos/${REPO}/environments/${env_name}" >/dev/null
  echo "   - ${env_name}"
done

echo "==> Setting repository variables"
gh variable set ENABLE_DEPLOY --repo "$REPO" --body "true"
gh variable set AWS_ROLE_TO_ASSUME --repo "$REPO" --body "$ROLE_ARN"
gh variable set TF_STATE_BUCKET --repo "$REPO" --body "$STATE_BUCKET"
gh variable set TF_STATE_PREFIX --repo "$REPO" --body "$STATE_PREFIX"
gh variable set AWS_REGION --repo "$REPO" --body "$AWS_REGION_VALUE"

echo "==> Setting environment variables"
for env_name in dev staging prod; do
  gh variable set AWS_ROLE_TO_ASSUME --repo "$REPO" --env "$env_name" --body "$ROLE_ARN"
  gh variable set TF_STATE_BUCKET --repo "$REPO" --env "$env_name" --body "$STATE_BUCKET"
  gh variable set TF_STATE_PREFIX --repo "$REPO" --env "$env_name" --body "$STATE_PREFIX"
  gh variable set AWS_REGION --repo "$REPO" --env "$env_name" --body "$AWS_REGION_VALUE"
  echo "   - ${env_name}"
done

echo "==> Bootstrap complete"
echo "Next: run Deploy workflow manually with environment=dev and confirm=APPLY"
