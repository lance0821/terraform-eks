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
