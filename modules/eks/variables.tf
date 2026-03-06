variable "name" {
  description = "EKS cluster name."
  type        = string
  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "create" {
  description = "Controls whether cluster resources are created. Useful for validation-only plans and tests."
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane (for example 1.31)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed."
  type        = string
  validation {
    condition     = trimspace(var.vpc_id) != ""
    error_message = "vpc_id must not be empty."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs used by the EKS control plane and node groups."
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet ID."
  }
}

################################################################################
# API Endpoint
################################################################################

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API server endpoint is publicly accessible."
  type        = bool
  default     = false
}

variable "endpoint_private_access" {
  description = "Whether the Kubernetes API server endpoint is privately accessible."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public API endpoint. Only applies when endpoint_public_access = true."
  type        = list(string)
  default     = []
  validation {
    condition     = !contains(var.cluster_endpoint_public_access_cidrs, "0.0.0.0/0") || length(var.cluster_endpoint_public_access_cidrs) == 0
    error_message = "Do not use 0.0.0.0/0 in cluster_endpoint_public_access_cidrs. Restrict to known CIDRs or leave empty."
  }
}

################################################################################
# Control Plane Logging
################################################################################

variable "cluster_enabled_log_types" {
  description = "List of control plane log types to enable. Valid values: api, audit, authenticator, controllerManager, scheduler."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

################################################################################
# Encryption
################################################################################

variable "create_kms_key" {
  description = "Create a KMS key for cluster encryption."
  type        = bool
  default     = true
}

variable "cluster_encryption_config" {
  description = "Encryption config. Defaults to secrets encryption."
  type = object({
    resources        = list(string)
    provider_key_arn = optional(string)
  })
  default = {
    resources = ["secrets"]
  }
}


variable "kms_key_enable_default_policy" {
  description = "Specifies whether the default KMS key policy is enabled."
  type        = bool
  default     = true
}

################################################################################
# IRSA & Access
################################################################################

variable "enable_irsa" {
  description = "Whether to enable IAM Roles for Service Accounts (IRSA)."
  type        = bool
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Whether the cluster creator should get admin permissions."
  type        = bool
  default     = false
}

variable "access_entries" {
  description = "Map of EKS access entries for IAM principal access management."
  type = map(object({
    principal_arn = string
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        type       = string
        namespaces = optional(list(string))
      })
    })), {})
  }))
  default = {}
}

################################################################################
# Security Groups
################################################################################

variable "node_security_group_additional_rules" {
  description = "Additional rules for the node security group."
  type = map(object({
    description                   = optional(string)
    from_port                     = number
    to_port                       = number
    protocol                      = string
    type                          = string
    cidr_blocks                   = optional(list(string))
    source_security_group_id      = optional(string)
    source_cluster_security_group = optional(bool)
    self                          = optional(bool)
  }))
  default = {}
}

variable "cluster_security_group_additional_rules" {
  description = "Additional rules for the cluster security group."
  type = map(object({
    description              = optional(string)
    from_port                = number
    to_port                  = number
    protocol                 = string
    type                     = string
    cidr_blocks              = optional(list(string))
    source_security_group_id = optional(string)
    self                     = optional(bool)
  }))
  default = {}
}

################################################################################
# Compute & Addons
################################################################################

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions."
  type        = any
  default     = {}
}

variable "addons" {
  description = "Map of EKS add-on definitions."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags applied to cluster resources."
  type        = map(string)
  default     = {}
}
