variable "name" {
  description = "EKS cluster name."
  type        = string
  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
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

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API server endpoint is publicly accessible."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the Kubernetes API server endpoint is privately accessible."
  type        = bool
  default     = true
}

variable "enable_irsa" {
  description = "Whether to enable IAM Roles for Service Accounts (IRSA)."
  type        = bool
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Whether the cluster creator should get admin permissions."
  type        = bool
  default     = true
}

variable "access_entries" {
  description = "Map of EKS access entries passed to the upstream module for IAM principal access management."
  type        = any
  default     = {}
}

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
