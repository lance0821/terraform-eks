#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Render and optionally create least-privilege IAM policies for Fluent Bit outputs.

Required:
  --template cloudwatch|s3|opensearch
  --policy-name NAME

Optional:
  --region REGION               AWS region (default: us-east-1)
  --account-id ID               AWS account ID (defaults to caller account)
  --log-group-name NAME         Required for cloudwatch template
  --bucket-name NAME            Required for s3 template
  --prefix PREFIX               Required for s3 template
  --domain-name NAME            Required for opensearch template
  --aws-profile NAME            AWS profile for AWS CLI calls
  --render-only                 Only render policy JSON (do not create IAM policy)
  --output PATH                 Output path for rendered JSON

Examples:
  ./scripts/create-fluent-bit-policy.sh \
    --template cloudwatch \
    --policy-name FluentBitCloudWatchLogsWrite \
    --region us-east-1 \
    --log-group-name /aws/eks/terraform-eks/cluster

  ./scripts/create-fluent-bit-policy.sh \
    --template s3 \
    --policy-name FluentBitS3Write \
    --bucket-name my-eks-logs-bucket \
    --prefix fluent-bit/dev

  ./scripts/create-fluent-bit-policy.sh \
    --template opensearch \
    --policy-name FluentBitOpenSearchWrite \
    --domain-name my-logs-domain \
    --render-only
EOF
}

TEMPLATE=""
POLICY_NAME=""
REGION="us-east-1"
ACCOUNT_ID=""
LOG_GROUP_NAME=""
BUCKET_NAME=""
PREFIX=""
DOMAIN_NAME=""
AWS_PROFILE_NAME=""
RENDER_ONLY="false"
OUTPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template)
      TEMPLATE="$2"; shift 2 ;;
    --policy-name)
      POLICY_NAME="$2"; shift 2 ;;
    --region)
      REGION="$2"; shift 2 ;;
    --account-id)
      ACCOUNT_ID="$2"; shift 2 ;;
    --log-group-name)
      LOG_GROUP_NAME="$2"; shift 2 ;;
    --bucket-name)
      BUCKET_NAME="$2"; shift 2 ;;
    --prefix)
      PREFIX="$2"; shift 2 ;;
    --domain-name)
      DOMAIN_NAME="$2"; shift 2 ;;
    --aws-profile)
      AWS_PROFILE_NAME="$2"; shift 2 ;;
    --render-only)
      RENDER_ONLY="true"; shift ;;
    --output)
      OUTPUT_PATH="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1 ;;
  esac
done

if [[ -z "$TEMPLATE" || -z "$POLICY_NAME" ]]; then
  echo "--template and --policy-name are required" >&2
  usage
  exit 1
fi

if ! command -v envsubst >/dev/null 2>&1; then
  echo "envsubst not found. Install gettext-base (e.g. 'sudo apt-get install -y gettext-base')." >&2
  exit 1
fi

if [[ -n "$AWS_PROFILE_NAME" ]]; then
  export AWS_PROFILE="$AWS_PROFILE_NAME"
fi

if [[ -z "$ACCOUNT_ID" ]]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
fi

export REGION ACCOUNT_ID LOG_GROUP_NAME BUCKET_NAME PREFIX DOMAIN_NAME

TEMPLATE_DIR="examples/fluent-bit/policies"
case "$TEMPLATE" in
  cloudwatch)
    TEMPLATE_FILE="${TEMPLATE_DIR}/cloudwatch-logs-write-policy.json"
    [[ -n "$LOG_GROUP_NAME" ]] || { echo "--log-group-name is required for cloudwatch" >&2; exit 1; }
    ;;
  s3)
    TEMPLATE_FILE="${TEMPLATE_DIR}/s3-write-policy.json"
    [[ -n "$BUCKET_NAME" ]] || { echo "--bucket-name is required for s3" >&2; exit 1; }
    [[ -n "$PREFIX" ]] || { echo "--prefix is required for s3" >&2; exit 1; }
    ;;
  opensearch)
    TEMPLATE_FILE="${TEMPLATE_DIR}/opensearch-write-policy.json"
    [[ -n "$DOMAIN_NAME" ]] || { echo "--domain-name is required for opensearch" >&2; exit 1; }
    ;;
  *)
    echo "Invalid --template value: $TEMPLATE" >&2
    usage
    exit 1 ;;
esac

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Template file not found: $TEMPLATE_FILE" >&2
  exit 1
fi

if [[ -z "$OUTPUT_PATH" ]]; then
  OUTPUT_PATH="/tmp/${POLICY_NAME}.json"
fi

envsubst < "$TEMPLATE_FILE" > "$OUTPUT_PATH"
echo "Rendered policy JSON: $OUTPUT_PATH"

if [[ "$RENDER_ONLY" == "true" ]]; then
  exit 0
fi

POLICY_ARN=$(aws iam create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document "file://${OUTPUT_PATH}" \
  --query 'Policy.Arn' \
  --output text)

echo "Created policy ARN: $POLICY_ARN"
