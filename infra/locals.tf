locals {
  name = "${var.project_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  private_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + var.az_count)]

  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.extra_tags
  )
}
