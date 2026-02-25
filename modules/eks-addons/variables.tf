variable "cluster_name" {
	description = "EKS cluster name used by the add-ons module."
	type        = string
	validation {
		condition     = trimspace(var.cluster_name) != ""
		error_message = "cluster_name must not be empty."
	}
}

variable "cluster_endpoint" {
	description = "EKS cluster endpoint used by add-ons."
	type        = string
	validation {
		condition     = trimspace(var.cluster_endpoint) != ""
		error_message = "cluster_endpoint must not be empty."
	}
}

variable "cluster_version" {
	description = "Kubernetes version of the EKS cluster."
	type        = string
}

variable "region" {
	description = "AWS region where the EKS cluster exists."
	type        = string
}

variable "vpc_id" {
	description = "VPC ID used by AWS Load Balancer Controller Helm values."
	type        = string
	validation {
		condition     = trimspace(var.vpc_id) != ""
		error_message = "vpc_id must not be empty."
	}
}

variable "oidc_provider_arn" {
	description = "OIDC provider ARN for IRSA-enabled add-ons."
	type        = string
	validation {
		condition     = trimspace(var.oidc_provider_arn) != ""
		error_message = "oidc_provider_arn must not be empty."
	}
}

variable "enable_aws_load_balancer_controller" {
	description = "Enable AWS Load Balancer Controller installation."
	type        = bool
	default     = true
}

variable "enable_metrics_server" {
	description = "Enable metrics-server installation."
	type        = bool
	default     = true
}

variable "enable_external_dns" {
	description = "Enable external-dns installation."
	type        = bool
	default     = false
}

variable "aws_load_balancer_controller" {
	description = "Configuration overrides for AWS Load Balancer Controller (namespace, chart_version, service_account_name, values)."
	type        = map(any)
	default     = {}
}

variable "metrics_server" {
	description = "Configuration overrides for metrics-server (namespace, chart_version, values)."
	type        = map(any)
	default     = {}
}

variable "external_dns" {
	description = "Reserved for future external-dns support."
	type        = map(any)
	default     = {}
}

variable "tags" {
	description = "Tags applied to add-on resources."
	type        = map(string)
	default     = {}
}
