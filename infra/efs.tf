locals {
  efs_subnet_ids = length(var.efs_subnet_ids) > 0 ? var.efs_subnet_ids : module.vpc.private_subnets
}

resource "aws_security_group" "efs" {
  count = var.enable_efs_filesystem ? 1 : 0

  name_prefix = "${local.name}-efs-"
  description = "Allow EKS nodes to mount EFS over NFS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "NFS from EKS worker nodes"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-efs"
  })
}

resource "aws_efs_file_system" "this" {
  count = var.enable_efs_filesystem ? 1 : 0

  creation_token   = "${local.name}-efs"
  encrypted        = var.efs_encrypted
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode

  tags = merge(local.tags, {
    Name = "${local.name}-efs"
  })
}

resource "aws_efs_mount_target" "this" {
  for_each = var.enable_efs_filesystem ? toset(local.efs_subnet_ids) : toset([])

  file_system_id  = aws_efs_file_system.this[0].id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs[0].id]
}
