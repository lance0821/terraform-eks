output "aws_load_balancer_controller_enabled" {
	description = "Whether AWS Load Balancer Controller is enabled."
	value       = var.enable_aws_load_balancer_controller
}

output "aws_load_balancer_controller_irsa_role_arn" {
	description = "IRSA role ARN used by AWS Load Balancer Controller, if enabled."
	value       = var.enable_aws_load_balancer_controller ? module.aws_load_balancer_controller_irsa_role[0].iam_role_arn : null
}

output "aws_load_balancer_controller_release_name" {
	description = "Helm release name for AWS Load Balancer Controller, if enabled."
	value       = var.enable_aws_load_balancer_controller ? helm_release.aws_load_balancer_controller[0].name : null
}

output "metrics_server_enabled" {
	description = "Whether metrics-server is enabled."
	value       = var.enable_metrics_server
}

output "metrics_server_release_name" {
	description = "Helm release name for metrics-server, if enabled."
	value       = var.enable_metrics_server ? helm_release.metrics_server[0].name : null
}

output "external_dns_enabled" {
	description = "Whether external-dns is enabled."
	value       = var.enable_external_dns
}
