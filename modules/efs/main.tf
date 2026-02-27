resource "aws_security_group" "this" {
  count = var.create ? 1 : 0

  name_prefix = "${var.name}-efs-"
  description = "Allow NFS access from specified security groups"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from allowed security groups"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    description = "NFS outbound within VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, { Name = "${var.name}-efs" })
}

resource "aws_efs_file_system" "this" {
  count = var.create ? 1 : 0

  creation_token   = "${var.name}-efs"
  encrypted        = var.encrypted
  kms_key_id       = var.kms_key_id
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode

  provisioned_throughput_in_mibps = (
    var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null
  )

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy != null ? [var.lifecycle_policy] : []

    content {
      transition_to_ia                    = lifecycle_policy.value.transition_to_ia
      transition_to_primary_storage_class = lifecycle_policy.value.transition_to_primary_storage_class
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-efs" })
}

resource "aws_efs_backup_policy" "this" {
  count = var.create ? 1 : 0

  file_system_id = aws_efs_file_system.this[0].id

  backup_policy {
    status = var.enable_backup_policy ? "ENABLED" : "DISABLED"
  }
}

resource "aws_efs_mount_target" "this" {
  for_each = var.create ? toset(var.subnet_ids) : toset([])

  file_system_id  = aws_efs_file_system.this[0].id
  subnet_id       = each.value
  security_groups = [aws_security_group.this[0].id]
}