################################################################################
# AWS Load Balancer Controller
################################################################################

locals {
  alb_defaults = {
    chart_version        = "1.14.0"
    namespace            = "kube-system"
    service_account_name = "aws-load-balancer-controller"
  }
  alb = merge(local.alb_defaults, var.aws_load_balancer_controller)
}

module "aws_load_balancer_controller" {
  source = "../helm-release"

  create = var.enable_aws_load_balancer_controller

  name          = "aws-load-balancer-controller"
  repository    = "https://aws.github.io/eks-charts"
  chart         = "aws-load-balancer-controller"
  chart_version = local.alb.chart_version
  namespace     = local.alb.namespace

  values = lookup(local.alb, "values", [])

  set = [
    { name = "clusterName", value = var.cluster_name },
    { name = "region", value = var.region },
    { name = "vpcId", value = var.vpc_id },
  ]

  create_irsa_role                            = true
  irsa_role_name_prefix                       = "${var.cluster_name}-alb-controller"
  irsa_service_account_name                   = local.alb.service_account_name
  irsa_annotation_key                         = "serviceAccount"
  oidc_provider_arn                           = var.oidc_provider_arn
  irsa_attach_load_balancer_controller_policy = true

  tags = var.tags
}

################################################################################
# Metrics Server
################################################################################

locals {
  metrics_defaults = {
    chart_version = "3.13.0"
    namespace     = "kube-system"
  }
  metrics = merge(local.metrics_defaults, var.metrics_server)
}

module "metrics_server" {
  source = "../helm-release"

  create = var.enable_metrics_server

  name          = "metrics-server"
  repository    = "https://kubernetes-sigs.github.io/metrics-server"
  chart         = "metrics-server"
  chart_version = local.metrics.chart_version
  namespace     = local.metrics.namespace

  values = lookup(local.metrics, "values", [])

  tags = var.tags
}

################################################################################
# External DNS
################################################################################

locals {
  extdns_defaults = {
    chart_version        = "1.20.0"
    namespace            = "kube-system"
    service_account_name = "external-dns"
  }
  extdns = merge(local.extdns_defaults, var.external_dns)
}

module "external_dns" {
  source = "../helm-release"

  create = var.enable_external_dns

  name          = "external-dns"
  repository    = "https://kubernetes-sigs.github.io/external-dns"
  chart         = "external-dns"
  chart_version = local.extdns.chart_version
  namespace     = local.extdns.namespace

  values = lookup(local.extdns, "values", [])

  set = [
    { name = "provider.name", value = "aws" },
    { name = "policy", value = "sync" },
    { name = "txtOwnerId", value = var.cluster_name },
  ]

  create_irsa_role                = true
  irsa_role_name_prefix           = "${var.cluster_name}-external-dns"
  irsa_service_account_name       = local.extdns.service_account_name
  irsa_annotation_key             = "serviceAccount"
  oidc_provider_arn               = var.oidc_provider_arn
  irsa_attach_external_dns_policy = true

  tags = var.tags
}

################################################################################
# cert-manager
################################################################################

locals {
  certmgr_defaults = {
    chart_version        = "v1.17.2"
    namespace            = "cert-manager"
    service_account_name = "cert-manager"
  }
  certmgr = merge(local.certmgr_defaults, var.cert_manager)
}

module "cert_manager" {
  source = "../helm-release"

  create = var.enable_cert_manager

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  chart_version    = local.certmgr.chart_version
  namespace        = local.certmgr.namespace
  create_namespace = true

  values = concat(
    [yamlencode({ crds = { enabled = true } })],
    lookup(local.certmgr, "values", [])
  )

  create_irsa_role                = true
  irsa_role_name_prefix           = "${var.cluster_name}-cert-manager"
  irsa_service_account_name       = local.certmgr.service_account_name
  irsa_annotation_key             = "serviceAccount"
  oidc_provider_arn               = var.oidc_provider_arn
  irsa_attach_cert_manager_policy = true

  tags = var.tags
}

################################################################################
# kube-prometheus-stack (Prometheus + Grafana + Alertmanager + exporters)
################################################################################

locals {
  promstack_defaults = {
    chart_version = "82.4.0"
    namespace     = "monitoring"
  }
  promstack = merge(local.promstack_defaults, var.kube_prometheus_stack)
}

module "kube_prometheus_stack" {
  source = "../helm-release"

  create = var.enable_kube_prometheus_stack

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  chart_version    = local.promstack.chart_version
  namespace        = local.promstack.namespace
  create_namespace = true
  timeout          = 600
  skip_crds        = false

  values = concat(
    [yamlencode({
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
        }
      }
      grafana = {
        sidecar = {
          dashboards  = { enabled = true }
          datasources = { enabled = true }
        }
      }
    })],
    lookup(local.promstack, "values", [])
  )

  tags = var.tags
}

################################################################################
# Karpenter
#
# NOTE: Karpenter also requires:
#   - An instance profile for nodes it launches
#   - SQS queue for spot interruption handling
#   - Additional IAM policies beyond basic IRSA
# These are NOT managed here. Use the terraform-aws-modules/eks module's
# Karpenter sub-module or create them separately and pass the ARNs via
# the karpenter override map's `set` or `values`.
################################################################################

locals {
  karpenter_defaults = {
    chart_version        = "1.4.0"
    namespace            = "karpenter"
    service_account_name = "karpenter"
  }
  karpenter = merge(local.karpenter_defaults, var.karpenter)
}

module "karpenter" {
  source = "../helm-release"

  create = var.enable_karpenter

  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  chart_version    = local.karpenter.chart_version
  namespace        = local.karpenter.namespace
  create_namespace = true
  timeout          = 600

  values = concat(
    [yamlencode({
      settings = {
        clusterName     = var.cluster_name
        clusterEndpoint = var.cluster_endpoint
      }
    })],
    lookup(local.karpenter, "values", [])
  )

  # IRSA handles the base role; callers must supply the Karpenter-specific
  # policies via irsa_policy_arns in the karpenter override map.
  create_irsa_role          = true
  irsa_role_name_prefix     = "${var.cluster_name}-karpenter"
  irsa_service_account_name = local.karpenter.service_account_name
  irsa_annotation_key       = "serviceAccount"
  oidc_provider_arn         = var.oidc_provider_arn
  irsa_policy_arns          = lookup(local.karpenter, "irsa_policy_arns", {})

  tags = var.tags
}

check "karpenter_requires_irsa_policies" {
  assert {
    condition     = !var.enable_karpenter || length(lookup(local.karpenter, "irsa_policy_arns", {})) > 0
    error_message = "When enabling Karpenter, you must provide at least one policy ARN via the `karpenter.irsa_policy_arns` variable."
  }
}

################################################################################
# Argo CD
################################################################################

locals {
  argocd_defaults = {
    chart_version = "7.8.13"
    namespace     = "argocd"
  }
  argocd = merge(local.argocd_defaults, var.argocd)
}

module "argocd" {
  source = "../helm-release"

  create = var.enable_argocd

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  chart_version    = local.argocd.chart_version
  namespace        = local.argocd.namespace
  create_namespace = true
  timeout          = 600

  values = lookup(local.argocd, "values", [])

  tags = var.tags
}

################################################################################
# Generic Helm Releases (deploy any chart not listed above)
################################################################################

module "helm_releases" {
  source   = "../helm-release"
  for_each = var.helm_releases

  create = try(each.value.create, true)

  name             = try(each.value.name, each.key)
  repository       = try(each.value.repository, null)
  chart            = each.value.chart
  chart_version    = each.value.chart_version
  namespace        = try(each.value.namespace, "kube-system")
  create_namespace = try(each.value.create_namespace, false)
  description      = try(each.value.description, null)

  values        = try(each.value.values, [])
  set           = try(each.value.set, [])
  set_sensitive = try(each.value.set_sensitive, [])

  timeout           = try(each.value.timeout, 300)
  atomic            = try(each.value.atomic, false)
  cleanup_on_fail   = try(each.value.cleanup_on_fail, false)
  wait              = try(each.value.wait, true)
  wait_for_jobs     = try(each.value.wait_for_jobs, false)
  force_update      = try(each.value.force_update, false)
  recreate_pods     = try(each.value.recreate_pods, false)
  max_history       = try(each.value.max_history, 5)
  dependency_update = try(each.value.dependency_update, false)
  skip_crds         = try(each.value.skip_crds, false)
  lint              = try(each.value.lint, false)

  create_irsa_role          = try(each.value.create_irsa_role, false)
  irsa_role_name_prefix     = try(each.value.irsa_role_name_prefix, "${var.cluster_name}-${each.key}")
  irsa_service_account_name = try(each.value.irsa_service_account_name, "")
  irsa_annotation_key       = try(each.value.irsa_annotation_key, "serviceAccount")
  oidc_provider_arn         = var.oidc_provider_arn
  irsa_policy_arns          = try(each.value.irsa_policy_arns, {})

  irsa_attach_load_balancer_controller_policy = try(each.value.irsa_attach_load_balancer_controller_policy, false)
  irsa_attach_external_dns_policy             = try(each.value.irsa_attach_external_dns_policy, false)
  irsa_attach_cert_manager_policy             = try(each.value.irsa_attach_cert_manager_policy, false)
  irsa_attach_ebs_csi_policy                  = try(each.value.irsa_attach_ebs_csi_policy, false)
  irsa_attach_efs_csi_policy                  = try(each.value.irsa_attach_efs_csi_policy, false)

  tags = var.tags
}
