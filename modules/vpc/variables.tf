variable "name" {
  description = "Name prefix for VPC resources."
  type        = string
}

variable "cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "CIDR must be a valid IPv4 CIDR block (for example 10.0.0.0/16)."
  }
}

variable "azs" {
  description = "Availability zones to use."
  type        = list(string)
  validation {
    condition     = length(var.azs) > 0
    error_message = "AZs must contain at least one availability zone."
  }
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks (one per AZ)."
  type        = list(string)
  validation {
    condition     = length(var.private_subnets) == length(var.azs)
    error_message = "Private_subnets must contain exactly one CIDR per availability zone in AZs	."
  }
  validation {
    condition     = alltrue([for subnet in var.private_subnets : can(cidrhost(subnet, 0))])
    error_message = "Each entry in private_subnets must be a valid IPv4 CIDR block."
  }
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks (one per AZ)."
  type        = list(string)
  validation {
    condition     = length(var.public_subnets) == length(var.azs)
    error_message = "Public Subnets must contain exactly one CIDR per availability zone in AZs."
  }
  validation {
    condition     = alltrue([for subnet in var.public_subnets : can(cidrhost(subnet, 0))])
    error_message = "Each entry in public_subnets must be a valid IPv4 CIDR block."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateway resources."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to create a single shared NAT gateway."
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Whether to create one NAT gateway per AZ."
  type        = bool
  default     = false
  validation {
    condition     = !(var.single_nat_gateway && var.one_nat_gateway_per_az)
    error_message = "single_nat_gateway and one_nat_gateway_per_az cannot both be true."
  }
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets."
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to all VPC resources."
  type        = map(string)
  default     = {}
}
