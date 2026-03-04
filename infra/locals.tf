locals {
  name = "${var.project_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  private_subnet_parent_cidr = cidrsubnet(var.vpc_cidr, 1, 0)
  public_subnet_parent_cidr  = cidrsubnet(var.vpc_cidr, 1, 1)

  private_subnets = [for i in range(var.az_count) : cidrsubnet(local.private_subnet_parent_cidr, 4, i)]
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(local.public_subnet_parent_cidr, 4, i)]

  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.extra_tags
  )
}
