locals {
	aws_load_balancer_controller = merge(
		{
			namespace            = "kube-system"
			chart_version        = "1.14.0"
			service_account_name = "aws-load-balancer-controller"
			values               = []
		},
		var.aws_load_balancer_controller
	)

	metrics_server = merge(
		{
			namespace     = "kube-system"
			chart_version = "3.13.0"
			values        = []
		},
		var.metrics_server
	)
}

module "aws_load_balancer_controller_irsa_role" {
	count = var.enable_aws_load_balancer_controller ? 1 : 0

	source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
	version = "~> 5.0"

	role_name_prefix                              = "${var.cluster_name}-alb-controller-"
	attach_load_balancer_controller_policy        = true

	oidc_providers = {
		main = {
			provider_arn               = var.oidc_provider_arn
			namespace_service_accounts = ["${local.aws_load_balancer_controller.namespace}:${local.aws_load_balancer_controller.service_account_name}"]
		}
	}

	tags = var.tags
}

resource "helm_release" "aws_load_balancer_controller" {
	count = var.enable_aws_load_balancer_controller ? 1 : 0

	name             = "aws-load-balancer-controller"
	repository       = "https://aws.github.io/eks-charts"
	chart            = "aws-load-balancer-controller"
	namespace        = local.aws_load_balancer_controller.namespace
	create_namespace = false
	version          = local.aws_load_balancer_controller.chart_version

	values = [for value in local.aws_load_balancer_controller.values : tostring(value)]

	set = [
		{
			name  = "clusterName"
			value = var.cluster_name
		},
		{
			name  = "region"
			value = var.region
		},
		{
			name  = "vpcId"
			value = var.vpc_id
		},
		{
			name  = "serviceAccount.create"
			value = "true"
		},
		{
			name  = "serviceAccount.name"
			value = local.aws_load_balancer_controller.service_account_name
		},
		{
			name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
			value = module.aws_load_balancer_controller_irsa_role[0].iam_role_arn
		}
	]
}

resource "helm_release" "metrics_server" {
	count = var.enable_metrics_server ? 1 : 0

	name             = "metrics-server"
	repository       = "https://kubernetes-sigs.github.io/metrics-server"
	chart            = "metrics-server"
	namespace        = local.metrics_server.namespace
	create_namespace = false
	version          = local.metrics_server.chart_version

	values = [for value in local.metrics_server.values : tostring(value)]
}
