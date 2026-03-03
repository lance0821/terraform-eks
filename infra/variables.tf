variable "region" {
  type        = string
  description = "AWS region for all resources."
  default     = "us-east-1"
  validation {
    condition     = can(regex("^[a-z]{2}(?:-[a-z]+)+-[0-9]+$", lower(trimspace(var.region))))
    error_message = "region must look like a valid AWS region (for example us-east-1)."
  }
}

variable "project_name" {
  type        = string
  description = "Short project slug for naming."
  validation {
    condition     = trimspace(var.project_name) != "" && lower(trimspace(var.project_name)) != "terraform-template"
    error_message = "project_name must be set to a real project value and cannot be \"terraform-template\"."
  }
}

variable "environment" {
  type        = string
  description = "dev|staging|prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], lower(trimspace(var.environment))) && lower(trimspace(var.environment)) != "template"
    error_message = "environment must be one of dev, staging, or prod, and cannot be the placeholder value \"template\"."
  }
}

variable "extra_tags" {
  type        = map(string)
  description = "Additional tags merged into all resources."
  default     = {}
  validation {
    condition = (
      !contains(keys(var.extra_tags), "Owner") ||
      lower(trimspace(var.extra_tags["Owner"])) != "owner"
      ) && (
      !contains(keys(var.extra_tags), "Team") ||
      lower(trimspace(var.extra_tags["Team"])) != "team"
    )
    error_message = "extra_tags placeholders are not allowed: set Owner and Team to real values (not \"Owner\"/\"Team\")."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "az_count" {
  type        = number
  description = "Number of AZs to use."
  default     = 3
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes version."
  default     = "1.31"
  validation {
    condition     = can(regex("^1\\.[0-9]+$", trimspace(var.kubernetes_version)))
    error_message = "kubernetes_version must be in major.minor format (for example 1.31)."
  }
}


variable "enable_cluster_creator_admin_permissions" {
  type        = bool
  description = "Whether the Terraform caller identity receives EKS cluster admin access."
  default     = true

  validation {
    condition     = !(var.enable_cluster_creator_admin_permissions && var.environment == "prod")
    error_message = "enable_cluster_creator_admin_permissions must be false in prod. Configure eks_access_entries for team access instead."
  }
}
variable "eks_access_entries" {
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
  description = "Map of EKS access entries to grant IAM principals cluster or namespace-scoped access."
  default     = {}
}

variable "eks_managed_node_groups" {
  type        = any
  description = "Managed node group map passed to EKS module."
  default     = {}
}

variable "eks_addons" {
  type        = any
  description = "EKS addons map passed to EKS module."
  default     = {}
}

variable "endpoint_public_access" {
  type        = bool
  description = "Whether the Kubernetes API server endpoint is publicly accessible."
  default     = false
}

variable "endpoint_private_access" {
  type        = bool
  description = "Whether the Kubernetes API server endpoint is privately accessible."
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to access the public API endpoint."
  default     = []
}

variable "cluster_enabled_log_types" {
  type        = list(string)
  description = "List of control plane log types to enable."
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "create_kms_key" {
  type        = bool
  description = "Create a KMS key for cluster secrets encryption."
  default     = true
}

variable "node_security_group_additional_rules" {
  type = map(object({
    description                  = optional(string)
    from_port                    = number
    to_port                      = number
    protocol                     = string
    type                         = string
    cidr_blocks                  = optional(list(string))
    source_security_group_id     = optional(string)
    source_cluster_security_group = optional(bool)
    self                         = optional(bool)
  }))
  description = "Additional security group rules for EKS node groups."
  default     = {}
}

variable "cluster_security_group_additional_rules" {
  type = map(object({
    description                  = optional(string)
    from_port                    = number
    to_port                      = number
    protocol                     = string
    type                         = string
    cidr_blocks                  = optional(list(string))
    source_security_group_id     = optional(string)
    self                         = optional(bool)
  }))
  description = "Additional security group rules for the EKS cluster."
  default     = {}
}

variable "enable_aws_load_balancer_controller" {
  type        = bool
  description = "Enable AWS Load Balancer Controller via eks-addons module."
  default     = true
}

variable "enable_metrics_server" {
  type        = bool
  description = "Enable metrics-server via eks-addons module."
  default     = true
}

variable "enable_external_dns" {
  type        = bool
  description = "Enable external-dns via eks-addons module."
  default     = false
}

variable "enable_cert_manager" {
  type        = bool
  description = "Enable cert-manager via eks-addons module."
  default     = true
}

variable "enable_kube_prometheus_stack" {
  type        = bool
  description = "Enable kube-prometheus-stack via eks-addons module."
  default     = true
}

variable "enable_karpenter" {
  type        = bool
  description = "Enable Karpenter via eks-addons module."
  default     = false
}

variable "enable_argocd" {
  type        = bool
  description = "Enable ArgoCD via eks-addons module."
  default     = false
}

variable "aws_load_balancer_controller_config" {
  type        = any
  description = "Configuration map passed to aws_load_balancer_controller in eks-addons module."
  default     = {}
}

variable "metrics_server_config" {
  type        = any
  description = "Configuration map passed to metrics_server in eks-addons module."
  default     = {}
}

variable "external_dns_config" {
  type        = any
  description = "Configuration map passed to external_dns in eks-addons module."
  default     = {}
}

variable "cert_manager_config" {
  type        = any
  description = "Configuration map passed to cert_manager in eks-addons module."
  default     = {}
}

variable "kube_prometheus_stack_config" {
  type        = any
  description = "Configuration map passed to kube_prometheus_stack in eks-addons module."
  default     = {}
}

variable "karpenter_config" {
  type        = any
  description = "Configuration map passed to karpenter in eks-addons module."
  default     = {}
}

variable "argocd_config" {
  type        = any
  description = "Configuration map passed to argo_cd in eks-addons module."
  default     = {}
}

variable "helm_releases" {
  type        = any
  description = "Map of Helm releases to install on the EKS cluster."
  default     = {}
}

variable "enable_fluent_bit_cloudwatch_policy" {
  type        = bool
  description = "Create and manage a least-privilege CloudWatch Logs IAM policy for fluent-bit IRSA when helm_releases.fluent_bit.create is true."
  default     = true
}

variable "fluent_bit_cloudwatch_log_group_name" {
  type        = string
  description = "CloudWatch Logs log group name for Fluent Bit output policy. If null, defaults to /aws/eks/<project>-<environment>/cluster."
  default     = null
}

variable "enable_efs_filesystem" {
  type        = bool
  description = "Create EFS filesystem and mount targets for EKS workloads."
  default     = false
}

variable "enable_ebs_csi_irsa" {
  type        = bool
  description = "Create a dedicated IRSA role for the EBS CSI driver addon. When true, the role ARN is automatically wired into eks_addons['aws-ebs-csi-driver']."
  default     = true
}

variable "efs_encrypted" {
  type        = bool
  description = "Enable encryption at rest for EFS filesystem."
  default     = true
}

variable "efs_performance_mode" {
  type        = string
  description = "EFS performance mode."
  default     = "generalPurpose"
  validation {
    condition     = contains(["generalPurpose", "maxIO"], trimspace(var.efs_performance_mode))
    error_message = "efs_performance_mode must be one of: generalPurpose, maxIO."
  }
}

variable "efs_throughput_mode" {
  type        = string
  description = "EFS throughput mode."
  default     = "bursting"
  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], lower(trimspace(var.efs_throughput_mode)))
    error_message = "efs_throughput_mode must be one of: bursting, provisioned, elastic."
  }
}

variable "efs_subnet_ids" {
  type        = list(string)
  description = "Optional subnet IDs for EFS mount targets. If empty, uses VPC private subnets."
  default     = []
}

variable "efs_kms_key_id" {
  type        = string
  description = "ARN of a customer-managed KMS key for EFS encryption. If null, uses the AWS-managed EFS key."
  default     = null
}

variable "efs_provisioned_throughput_in_mibps" {
  type        = number
  description = "Provisioned throughput in MiB/s. Only applies when efs_throughput_mode = provisioned."
  default     = null
  validation {
    condition     = var.efs_provisioned_throughput_in_mibps == null || var.efs_provisioned_throughput_in_mibps > 0
    error_message = "efs_provisioned_throughput_in_mibps must be positive when set."
  }
}

variable "efs_lifecycle_policy" {
  type = object({
    transition_to_ia                    = optional(string, "AFTER_30_DAYS")
    transition_to_primary_storage_class = optional(string, "AFTER_1_ACCESS")
  })
  description = "EFS lifecycle policy for transitioning files to Infrequent Access (IA)."
  default = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
  validation {
    condition = (
      var.efs_lifecycle_policy == null ||
      contains(
        ["AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS"],
        var.efs_lifecycle_policy.transition_to_ia
      )
    )
    error_message = "transition_to_ia must be one of: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS."
  }
}

variable "enable_efs_backup" {
  type        = bool
  description = "Enable AWS Backup automatic backups for the EFS filesystem."
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use a single NAT gateway (cost saving for dev, SPOF in prod). Mutually exclusive with one_nat_gateway_per_az."
  default     = true
}

variable "one_nat_gateway_per_az" {
  type        = bool
  description = "Deploy one NAT gateway per AZ for HA. Mutually exclusive with single_nat_gateway."
  default     = false
}