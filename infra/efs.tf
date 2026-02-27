module "efs" {
  source = "../modules/efs"

  create = var.enable_efs_filesystem

  name     = local.name
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr

  subnet_ids                 = length(var.efs_subnet_ids) > 0 ? var.efs_subnet_ids : module.vpc.private_subnets
  allowed_security_group_ids = [module.eks.node_security_group_id]

  encrypted        = var.efs_encrypted
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode

  tags = local.tags
}