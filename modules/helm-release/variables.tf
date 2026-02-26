################################################################################
# Helm Release
################################################################################

variable "create" {
  description = "Controls whether resources are created."
  type        = bool
  default     = true
}

variable "name" {
  description = "Release name."
  type        = string
}

variable "repository" {
  description = "Helm chart repository URL."
  type        = string
  default     = null
}

variable "chart" {
  description = "Chart name or path."
  type        = string
}

variable "chart_version" {
  description = "Pinned chart version. This value is required."
  type        = string
  validation {
    condition     = trimspace(var.chart_version) != ""
    error_message = "chart_version must not be empty. Pin an explicit chart version."
  }
}

variable "namespace" {
  description = "Kubernetes namespace for the release."
  type        = string
  default     = "kube-system"
}

variable "create_namespace" {
  description = "Create the namespace if it does not exist."
  type        = bool
  default     = false
}

variable "description" {
  description = "Helm release description."
  type        = string
  default     = null
}

variable "values" {
  description = "List of YAML value strings to pass to the chart."
  type        = list(string)
  default     = []
}

# Helm provider 3.x: set is a list of objects with name/value/type keys.
variable "set" {
  description = "List of value objects to pass to the chart. Each object has `name` (string), `value` (string), and optional `type` (string)."
  type = list(object({
    name  = string
    value = any
    type  = optional(string)
  }))
  default = []
}

variable "set_sensitive" {
  description = "List of sensitive value objects. Same shape as `set` but values are masked in plan output."
  type = list(object({
    name  = string
    value = string
    type  = optional(string)
  }))
  default = []
}

################################################################################
# Helm Release - Lifecycle & Behavior
################################################################################

variable "timeout" {
  description = "Timeout in seconds for Helm operations."
  type        = number
  default     = 300
}

variable "atomic" {
  description = "Purge the release on failure."
  type        = bool
  default     = false
}

variable "cleanup_on_fail" {
  description = "Delete new resources on failed upgrade."
  type        = bool
  default     = false
}

variable "wait" {
  description = "Wait for resources to be ready."
  type        = bool
  default     = true
}

variable "wait_for_jobs" {
  description = "Wait for all Jobs to complete."
  type        = bool
  default     = false
}

variable "force_update" {
  description = "Force resource update through delete/recreate."
  type        = bool
  default     = false
}

variable "recreate_pods" {
  description = "Restart pods during upgrade/rollback."
  type        = bool
  default     = false
}

variable "max_history" {
  description = "Maximum number of release versions stored per release. 0 = no limit."
  type        = number
  default     = 5
}

variable "dependency_update" {
  description = "Run helm dependency update before install."
  type        = bool
  default     = false
}

variable "replace" {
  description = "Re-use the given name if it is a deleted release."
  type        = bool
  default     = false
}

variable "reset_values" {
  description = "Reset chart values to defaults on upgrade."
  type        = bool
  default     = false
}

variable "reuse_values" {
  description = "Reuse the last release's values on upgrade."
  type        = bool
  default     = false
}

variable "skip_crds" {
  description = "Skip installing CRDs."
  type        = bool
  default     = false
}

variable "lint" {
  description = "Run helm lint before install."
  type        = bool
  default     = false
}

variable "disable_webhooks" {
  description = "Disable pre/post upgrade hooks."
  type        = bool
  default     = false
}

################################################################################
# IRSA (IAM Role for Service Account)
################################################################################

variable "create_irsa_role" {
  description = "Create an IAM role for a Kubernetes service account (IRSA)."
  type        = bool
  default     = false
}

variable "irsa_role_name_prefix" {
  description = "Prefix for the IRSA IAM role name."
  type        = string
  default     = ""
  validation {
    condition     = !var.create_irsa_role || trimspace(var.irsa_role_name_prefix) != ""
    error_message = "irsa_role_name_prefix must not be empty when create_irsa_role is true."
  }
}

variable "irsa_annotation_key" {
  description = <<-EOT
    Helm value path prefix for the service account that receives the IRSA
    role annotation. Charts place the SA at different paths:
      "serviceAccount"             → most charts (default)
      "server.serviceAccount"      → ArgoCD server
      "controller.serviceAccount"  → AWS LB controller, ingress-nginx
      "prometheus.serviceAccount"  → kube-prometheus-stack
  EOT
  type        = string
  default     = "serviceAccount"
}

variable "irsa_service_account_name" {
  description = "Kubernetes service account name for IRSA binding."
  type        = string
  default     = ""
  validation {
    condition     = !var.create_irsa_role || trimspace(var.irsa_service_account_name) != ""
    error_message = "irsa_service_account_name must not be empty when create_irsa_role is true."
  }
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA. Required when create_irsa_role = true."
  type        = string
  default     = ""
  validation {
    condition     = !var.create_irsa_role || trimspace(var.oidc_provider_arn) != ""
    error_message = "oidc_provider_arn must not be empty when create_irsa_role is true."
  }
}

variable "irsa_policy_arns" {
  description = "Map of IAM policy ARNs to attach to the IRSA role."
  type        = map(string)
  default     = {}
}

# Convenience flags for common managed policy attachments
variable "irsa_attach_load_balancer_controller_policy" {
  description = "Attach the AWS Load Balancer Controller IAM policy."
  type        = bool
  default     = false
}

variable "irsa_attach_external_dns_policy" {
  description = "Attach the External DNS IAM policy."
  type        = bool
  default     = false
}

variable "irsa_attach_cert_manager_policy" {
  description = "Attach the Cert Manager IAM policy."
  type        = bool
  default     = false
}

variable "irsa_attach_ebs_csi_policy" {
  description = "Attach the EBS CSI driver IAM policy."
  type        = bool
  default     = false
}

variable "irsa_attach_efs_csi_policy" {
  description = "Attach the EFS CSI driver IAM policy."
  type        = bool
  default     = false
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Tags applied to all IAM resources."
  type        = map(string)
  default     = {}
}
