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

module "eks_addons" {
  source = "../modules/eks-addons"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn
  region            = var.region
  vpc_id            = module.vpc.vpc_id

  # ── Baseline ───────────────────────────────────────────────────────────
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  aws_load_balancer_controller        = var.aws_load_balancer_controller_config

  enable_metrics_server = var.enable_metrics_server
  metrics_server        = var.metrics_server_config

  # ── DNS & TLS ──────────────────────────────────────────────────────────
  enable_external_dns = var.enable_external_dns
  external_dns        = var.external_dns_config

  enable_cert_manager = var.enable_cert_manager
  cert_manager        = var.cert_manager_config

  # ── Observability ──────────────────────────────────────────────────────
  enable_kube_prometheus_stack = var.enable_kube_prometheus_stack
  kube_prometheus_stack        = var.kube_prometheus_stack_config

  # ── Autoscaling ────────────────────────────────────────────────────────
  enable_karpenter = var.enable_karpenter
  karpenter        = var.karpenter_config

  # ── GitOps ─────────────────────────────────────────────────────────────
  enable_argocd = var.enable_argocd
  argocd        = var.argocd_config

  # ── Generic (any additional charts) ────────────────────────────────────
  helm_releases = var.helm_releases

  tags = local.tags
}
