data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" { state = "available" }

resource "terraform_data" "prod_guardrails" {
  lifecycle {
    precondition {
      condition     = var.environment != "prod" || !var.enable_cluster_creator_admin_permissions
      error_message = "enable_cluster_creator_admin_permissions must be false in prod. Configure eks_access_entries for team access instead."
    }
    precondition {
      condition     = var.environment != "prod" || var.one_nat_gateway_per_az
      error_message = "Production requires one_nat_gateway_per_az = true for high availability."
    }
  }
}


module "vpc" {
  source = "../modules/vpc"

  name                   = local.name
  cidr                   = var.vpc_cidr
  azs                    = local.azs
  private_subnets        = local.private_subnets
  public_subnets         = local.public_subnets
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

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
  source     = "../modules/eks"
  depends_on = [terraform_data.prod_guardrails]

  name               = local.name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  endpoint_public_access                  = var.endpoint_public_access
  endpoint_private_access                 = var.endpoint_private_access
  cluster_endpoint_public_access_cidrs    = var.cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types               = var.cluster_enabled_log_types
  create_kms_key                          = var.create_kms_key
  node_security_group_additional_rules    = var.node_security_group_additional_rules
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  access_entries                           = var.eks_access_entries
  eks_managed_node_groups                  = var.eks_managed_node_groups
  addons                                   = local.eks_addons_effective
  tags                                     = local.tags

}

resource "null_resource" "eks_node_readiness" {
  depends_on = [module.eks]

  triggers = {
    node_groups_hash = sha256(jsonencode(var.eks_managed_node_groups))
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -euo pipefail

      # Generate a temporary kubeconfig for kubectl commands
      TMPKUBECONFIG="/tmp/kubeconfig.$$"
      aws eks update-kubeconfig \
        --name "${module.eks.cluster_name}" \
        --region "${var.region}" \
        --kubeconfig "$TMPKUBECONFIG"
      export KUBECONFIG="$TMPKUBECONFIG"

      echo "Waiting for EKS node groups to become ACTIVE..."

      for ng in ${join(" ", keys(var.eks_managed_node_groups))}; do
        echo "  Waiting for node group: $ng"
        aws eks wait nodegroup-active \
          --cluster-name "${module.eks.cluster_name}" \
          --nodegroup-name "${module.eks.cluster_name}-$ng" \
          --region "${var.region}" 2>/dev/null || \
        aws eks wait nodegroup-active \
          --cluster-name "${module.eks.cluster_name}" \
          --nodegroup-name "$ng" \
          --region "${var.region}" 2>/dev/null || \
        echo "  Warning: could not wait for $ng (may already be active)"
      done

      echo "Waiting for nodes to join cluster..."
      for i in $(seq 1 60); do
        READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready ' || true)
        if [ "$READY" -gt 0 ]; then
          echo "✓ $READY node(s) Ready"
          rm -f "$TMPKUBECONFIG"
          exit 0
        fi
        echo "  Attempt $i/60: no Ready nodes yet, waiting 10s..."
        sleep 10
      done

      rm -f "$TMPKUBECONFIG"
      echo "ERROR: No nodes became Ready after 10 minutes" >&2
      exit 1
    EOT
    interpreter = ["bash", "-c"]
  }
}

module "eks_addons" {
  source = "../modules/eks-addons"

  depends_on = [null_resource.eks_node_readiness]

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
  helm_releases = local.helm_releases_effective

  tags = local.tags
}
