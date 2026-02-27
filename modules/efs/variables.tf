variable "create" {
  description = "Whether to create the EFS filesystem and related resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for EFS resources."
  type        = string
  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "vpc_id" {
  description = "VPC ID for the EFS security group."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for NFS egress rule."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for mount targets."
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet."
  }
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to mount this filesystem (e.g. EKS node SG)."
  type        = list(string)
  validation {
    condition     = length(var.allowed_security_group_ids) > 0
    error_message = "allowed_security_group_ids must contain at least one security group."
  }
}

variable "encrypted" {
  description = "Enable encryption at rest."
  type        = bool
  default     = true
}

variable "performance_mode" {
  description = "EFS performance mode."
  type        = string
  default     = "generalPurpose"
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "performance_mode must be generalPurpose or maxIO."
  }
}

variable "throughput_mode" {
  description = "EFS throughput mode."
  type        = string
  default     = "bursting"
  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "throughput_mode must be bursting, provisioned, or elastic."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "kms_key_id" {
  description = "ARN of a customer-managed KMS key for EFS encryption. If null, uses the AWS-managed EFS key (when encrypted = true)."
  type        = string
  default     = null
}

variable "lifecycle_policy" {
  description = "EFS lifecycle policy for transitioning files to Infrequent Access (IA). Set transition_to_ia to AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, or AFTER_90_DAYS. Set transition_to_primary_storage_class to AFTER_1_ACCESS to move files back on access."
  type = object({
    transition_to_ia                    = optional(string, "AFTER_30_DAYS")
    transition_to_primary_storage_class = optional(string, "AFTER_1_ACCESS")
  })
  default = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
  validation {
    condition = (
      var.lifecycle_policy == null ||
      contains(
        ["AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS"],
        var.lifecycle_policy.transition_to_ia
      )
    )
    error_message = "transition_to_ia must be one of: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS."
  }
}

variable "enable_backup_policy" {
  description = "Enable AWS Backup automatic backups for this filesystem."
  type        = bool
  default     = true
}

variable "provisioned_throughput_in_mibps" {
  description = "Provisioned throughput in MiB/s. Only applies when throughput_mode = provisioned."
  type        = number
  default     = null
  validation {
    condition     = var.provisioned_throughput_in_mibps == null || var.provisioned_throughput_in_mibps > 0
    error_message = "provisioned_throughput_in_mibps must be positive when set."
  }
}