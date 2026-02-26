variable "region" {
  type        = string
  description = "AWS region for all resources."
  default     = "us-east-1"
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
}

variable "enable_cluster_creator_admin_permissions" {
  type        = bool
  description = "Whether the Terraform caller identity receives EKS cluster admin access."
  default     = true
}

variable "eks_access_entries" {
  type        = any
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

variable "eks_addons_aws_load_balancer_controller" {
  type        = any
  description = "Configuration map passed to aws_load_balancer_controller in eks-addons module."
  default     = {}
}

variable "eks_addons_metrics_server" {
  type        = any
  description = "Configuration map passed to metrics_server in eks-addons module."
  default     = {}
}

variable "eks_addons_external_dns" {
  type        = any
  description = "Configuration map passed to external_dns in eks-addons module."
  default     = {}
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

variable "enable_efs_filesystem" {
  type        = bool
  description = "Create EFS filesystem and mount targets for EKS workloads."
  default     = false
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
}

variable "efs_throughput_mode" {
  type        = string
  description = "EFS throughput mode."
  default     = "bursting"
}

variable "efs_subnet_ids" {
  type        = list(string)
  description = "Optional subnet IDs for EFS mount targets. If empty, uses VPC private subnets."
  default     = []
}
