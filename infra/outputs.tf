################################################################################
# Account
################################################################################

output "account_id" {
  description = "AWS account ID of the current caller."
  value       = data.aws_caller_identity.current.account_id
}

################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnets
}

################################################################################
# EKS Cluster
################################################################################

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version."
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA."
  value       = module.eks.oidc_provider_arn
}

################################################################################
# Helm Addons
################################################################################

output "addon_alb_controller" {
  description = "AWS Load Balancer Controller status."
  value       = module.eks_addons.aws_load_balancer_controller
}

output "addon_metrics_server" {
  description = "Metrics Server status."
  value       = module.eks_addons.metrics_server
}

output "addon_external_dns" {
  description = "External DNS status."
  value       = module.eks_addons.external_dns
}

output "addon_cert_manager" {
  description = "cert-manager status."
  value       = module.eks_addons.cert_manager
}

output "addon_kube_prometheus_stack" {
  description = "kube-prometheus-stack status."
  value       = module.eks_addons.kube_prometheus_stack
}

output "addon_karpenter" {
  description = "Karpenter status."
  value       = module.eks_addons.karpenter
}

output "addon_argocd" {
  description = "Argo CD status."
  value       = module.eks_addons.argocd
}

output "addon_helm_releases" {
  description = "Generic Helm releases status map."
  value       = module.eks_addons.helm_releases
}

output "fluent_bit_cloudwatch_policy_arn" {
  description = "Terraform-managed Fluent Bit CloudWatch Logs policy ARN (if created)."
  value       = local.fluent_bit_cloudwatch_policy_enabled ? aws_iam_policy.fluent_bit_cloudwatch_logs_write[0].arn : null
}

################################################################################
# EFS
################################################################################

output "efs_file_system_id" {
  description = "EFS file system ID (if created)."
  value       = module.efs.file_system_id
}

output "efs_security_group_id" {
  description = "Security group ID attached to EFS mount targets (if created)."
  value       = module.efs.security_group_id
}

output "efs_mount_target_ids" {
  description = "Map of subnet ID to EFS mount target ID (if created)."
  value       = module.efs.mount_target_ids
}

output "ebs_csi_irsa_role_arn" {
  description = "IRSA role ARN for the EBS CSI driver (if created)."
  value       = var.enable_ebs_csi_irsa ? module.ebs_csi_irsa[0].arn : null
}

output "nat_public_ips" {
  description = "NAT gateway public IPs (for external allowlisting)."
  value       = module.vpc.nat_public_ips
}

output "node_security_group_id" {
  description = "Security group ID attached to EKS managed node groups."
  value       = module.eks.node_security_group_id
}