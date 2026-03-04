################################################################################
# Opinionated Addons
################################################################################

output "aws_load_balancer_controller" {
  description = "AWS Load Balancer Controller outputs."
  value = {
    enabled       = var.enable_aws_load_balancer_controller
    release_name  = module.aws_load_balancer_controller.release_name
    irsa_role_arn = module.aws_load_balancer_controller.irsa_role_arn
  }
}

output "metrics_server" {
  description = "Metrics Server outputs."
  value = {
    enabled      = var.enable_metrics_server
    release_name = module.metrics_server.release_name
  }
}

output "external_dns" {
  description = "External DNS outputs."
  value = {
    enabled       = var.enable_external_dns
    release_name  = module.external_dns.release_name
    irsa_role_arn = module.external_dns.irsa_role_arn
  }
}

output "cert_manager" {
  description = "cert-manager outputs."
  value = {
    enabled       = var.enable_cert_manager
    release_name  = module.cert_manager.release_name
    irsa_role_arn = module.cert_manager.irsa_role_arn
  }
}

output "kube_prometheus_stack" {
  description = "kube-prometheus-stack outputs."
  value = {
    enabled      = var.enable_kube_prometheus_stack
    release_name = module.kube_prometheus_stack.release_name
  }
}

output "karpenter" {
  description = "Karpenter outputs."
  value = {
    enabled       = var.enable_karpenter
    release_name  = module.karpenter.release_name
    irsa_role_arn = module.karpenter.irsa_role_arn
  }
}

output "argocd" {
  description = "Argo CD outputs."
  value = {
    enabled      = var.enable_argocd
    release_name = module.argocd.release_name
  }
}

################################################################################
# Generic Helm Releases
################################################################################

output "helm_releases" {
  description = "Map of all generic Helm release outputs."
  value = {
    for k, v in module.helm_releases : k => {
      release_name      = v.release_name
      release_namespace = v.release_namespace
      release_status    = v.release_status
      release_version   = v.release_version
      irsa_role_arn     = v.irsa_role_arn
    }
  }
}
