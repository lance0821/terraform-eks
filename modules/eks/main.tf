module "this" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name               = var.name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = var.endpoint_private_access

  enable_irsa                              = var.enable_irsa
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  eks_managed_node_groups = var.eks_managed_node_groups
  addons                  = var.addons

  tags = var.tags
}
