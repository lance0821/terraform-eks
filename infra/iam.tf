locals {
  fluent_bit_release_config = try(var.helm_releases.fluent_bit, null)

  fluent_bit_cloudwatch_log_group_name_effective = coalesce(
    var.fluent_bit_cloudwatch_log_group_name,
    "/aws/eks/${local.name}/cluster"
  )

  fluent_bit_cloudwatch_policy_enabled = (
    var.enable_fluent_bit_cloudwatch_policy &&
    local.fluent_bit_release_config != null &&
    try(local.fluent_bit_release_config.create, false)
  )
}

data "aws_iam_policy_document" "fluent_bit_cloudwatch_logs_write" {
  count = local.fluent_bit_cloudwatch_policy_enabled ? 1 : 0

  statement {
    sid    = "CloudWatchLogsWrite"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.fluent_bit_cloudwatch_log_group_name_effective}",
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.fluent_bit_cloudwatch_log_group_name_effective}:*",
    ]
  }
}

resource "aws_iam_policy" "fluent_bit_cloudwatch_logs_write" {
  count = local.fluent_bit_cloudwatch_policy_enabled ? 1 : 0

  name        = "${local.name}-FluentBitCloudWatchLogsWrite"
  description = "IRSA policy for Fluent Bit CloudWatch Logs write access"
  policy      = data.aws_iam_policy_document.fluent_bit_cloudwatch_logs_write[0].json
  tags        = local.tags
}

locals {
  fluent_bit_irsa_policy_arns = local.fluent_bit_cloudwatch_policy_enabled ? {
    cloudwatch_logs_write = aws_iam_policy.fluent_bit_cloudwatch_logs_write[0].arn
  } : {}

  helm_releases_effective = merge(
    var.helm_releases,
    local.fluent_bit_release_config == null ? {} : {
      fluent_bit = merge(
        local.fluent_bit_release_config,
        {
          irsa_policy_arns = merge(
            try(local.fluent_bit_release_config.irsa_policy_arns, {}),
            local.fluent_bit_irsa_policy_arns
          )
        }
      )
    }
  )
}
