module "this" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name               = var.name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # ── API endpoint ─────────────────────────────────────────────────────
  endpoint_public_access       = var.endpoint_public_access
  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # ── Control plane logging ────────────────────────────────────────────
  enabled_log_types = var.cluster_enabled_log_types

  # ── Encryption ───────────────────────────────────────────────────────
  create_kms_key                = var.create_kms_key
  encryption_config             = var.cluster_encryption_config
  kms_key_enable_default_policy = var.kms_key_enable_default_policy

  # ── IRSA & access ───────────────────────────────────────────────────
  enable_irsa                              = var.enable_irsa
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  access_entries                           = var.access_entries

  # ── Security groups ─────────────────────────────────────────────────
  node_security_group_additional_rules = var.node_security_group_additional_rules
  security_group_additional_rules      = var.cluster_security_group_additional_rules

  # ── Compute ─────────────────────────────────────────────────────────
  eks_managed_node_groups = var.eks_managed_node_groups
  addons                  = var.addons

  tags = var.tags
}
