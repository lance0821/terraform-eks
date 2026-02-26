################################################################################
# IRSA (IAM Role for Service Account)
# Created first so the role ARN is available for auto-injection into set.
################################################################################

module "irsa" {
  count = var.create && var.create_irsa_role ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name            = "${var.irsa_role_name_prefix}-"
  use_name_prefix = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${var.irsa_service_account_name}"]
    }
  }

  policies = {
    for index, policy_arn in var.irsa_policy_arns :
    "policy_${index}" => policy_arn
  }

  # Attach managed policies by flag (common patterns)
  attach_load_balancer_controller_policy = var.irsa_attach_load_balancer_controller_policy
  attach_external_dns_policy             = var.irsa_attach_external_dns_policy
  attach_cert_manager_policy             = var.irsa_attach_cert_manager_policy
  attach_ebs_csi_policy                  = var.irsa_attach_ebs_csi_policy
  attach_efs_csi_policy                  = var.irsa_attach_efs_csi_policy

  tags = var.tags
}

################################################################################
# Helm Release
################################################################################

locals {
  # Auto-inject the IRSA role ARN annotation into the chart's service account.
  # The caller controls the Helm value path via irsa_annotation_key, since
  # charts put the SA at different paths:
  #   "serviceAccount"                 → most charts (default)
  #   "server.serviceAccount"          → ArgoCD server
  #   "controller.serviceAccount"      → AWS LB controller, ingress-nginx
  #   "prometheus.serviceAccount"      → kube-prometheus-stack
  irsa_set = var.create && var.create_irsa_role ? [
    {
      name  = "${var.irsa_annotation_key}.create"
      value = "true"
    },
    {
      name  = "${var.irsa_annotation_key}.name"
      value = var.irsa_service_account_name
    },
    {
      name  = "${var.irsa_annotation_key}.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.irsa[0].arn
    },
  ] : []

  # Normalize caller-provided set values to strings.
  normalized_set = [
    for set_item in var.set :
    try(set_item.type, null) != null ? {
      name  = set_item.name
      value = tostring(set_item.value)
      type  = set_item.type
      } : {
      name  = set_item.name
      value = tostring(set_item.value)
    }
  ]

  # Caller-provided set values take precedence (appended last).
  # Helm uses last-wins for duplicate keys.
  merged_set = concat(local.irsa_set, local.normalized_set)
}

resource "helm_release" "this" {
  count = var.create ? 1 : 0

  name             = var.name
  repository       = var.repository
  chart            = var.chart
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace
  description      = var.description

  values = var.values

  # Lifecycle & behavior
  timeout           = var.timeout
  atomic            = var.atomic
  cleanup_on_fail   = var.cleanup_on_fail
  wait              = var.wait
  wait_for_jobs     = var.wait_for_jobs
  force_update      = var.force_update
  recreate_pods     = var.recreate_pods
  max_history       = var.max_history
  dependency_update = var.dependency_update
  replace           = var.replace
  reset_values      = var.reset_values
  reuse_values      = var.reuse_values
  skip_crds         = var.skip_crds
  lint              = var.lint
  disable_webhooks  = var.disable_webhooks

  # Merged: auto-injected IRSA annotation + caller-provided values.
  # Caller values appended last so they can override if needed.
  set = local.merged_set

  set_sensitive = var.set_sensitive

  depends_on = [module.irsa]
}
