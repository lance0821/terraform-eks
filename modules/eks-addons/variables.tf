################################################################################
# Cluster Context
################################################################################

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  validation {
    condition     = trimspace(var.cluster_name) != ""
    error_message = "cluster_name must not be empty."
  }
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint."
  type        = string
  validation {
    condition     = trimspace(var.cluster_endpoint) != ""
    error_message = "cluster_endpoint must not be empty."
  }
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (required by ALB controller)."
  type        = string
  validation {
    condition     = trimspace(var.vpc_id) != ""
    error_message = "vpc_id must not be empty."
  }
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA."
  type        = string
  validation {
    condition     = trimspace(var.oidc_provider_arn) != ""
    error_message = "oidc_provider_arn must not be empty."
  }
}

################################################################################
# AWS Load Balancer Controller
################################################################################

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller."
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller" {
  description = "Override defaults: chart_version, namespace, service_account_name, values."
  type        = any
  default     = {}
}

################################################################################
# Metrics Server
################################################################################

variable "enable_metrics_server" {
  description = "Enable metrics-server."
  type        = bool
  default     = true
}

variable "metrics_server" {
  description = "Override defaults: chart_version, namespace, values."
  type        = any
  default     = {}
}

################################################################################
# External DNS
################################################################################

variable "enable_external_dns" {
  description = "Enable external-dns with Route53."
  type        = bool
  default     = false
}

variable "external_dns" {
  description = "Override defaults: chart_version, namespace, service_account_name, values."
  type        = any
  default     = {}
}

################################################################################
# cert-manager
################################################################################

variable "enable_cert_manager" {
  description = "Enable cert-manager."
  type        = bool
  default     = false
}

variable "cert_manager" {
  description = "Override defaults: chart_version, namespace, service_account_name, values."
  type        = any
  default     = {}
}

################################################################################
# kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
################################################################################

variable "enable_kube_prometheus_stack" {
  description = "Enable kube-prometheus-stack (Prometheus, Grafana, Alertmanager, exporters)."
  type        = bool
  default     = false
}

variable "kube_prometheus_stack" {
  description = "Override defaults: chart_version, namespace, values."
  type        = any
  default     = {}
}

################################################################################
# Karpenter
################################################################################

variable "enable_karpenter" {
  description = "Enable Karpenter node autoscaler."
  type        = bool
  default     = false
}

variable "karpenter" {
  description = "Override defaults: chart_version, namespace, service_account_name, irsa_policy_arns, values."
  type        = any
  default     = {}
}

################################################################################
# Argo CD
################################################################################

variable "enable_argocd" {
  description = "Enable Argo CD."
  type        = bool
  default     = false
}

variable "argocd" {
  description = "Override defaults: chart_version, namespace, values."
  type        = any
  default     = {}
}

################################################################################
# Generic Helm Releases
################################################################################

variable "helm_releases" {
  description = <<-EOT
    Map of arbitrary Helm releases. Each key becomes the release name unless
    `name` is set. Supports all helm_release arguments plus optional IRSA.

    Example:
      helm_releases = {
        redis = {
          chart         = "redis"
          chart_version = "20.0.0"
          repository    = "https://charts.bitnami.com/bitnami"
          namespace     = "redis"
          create_namespace = true
        }
      }
  EOT
  type        = any
  default     = {}
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Tags applied to addon resources."
  type        = map(string)
  default     = {}
}
