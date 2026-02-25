data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" { state = "available" }


module "vpc" {
  source = "../modules/vpc"

  name            = local.name
  cidr            = var.vpc_cidr
  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"              = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  tags = local.tags
}

module "eks" {
  source = "../modules/eks"

  name               = local.name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true
  eks_managed_node_groups                  = var.eks_managed_node_groups
  addons                                   = var.eks_addons
  tags                                     = local.tags
}