output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.this.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = module.this.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS Kubernetes API server."
  value       = module.this.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster."
  value       = module.this.cluster_version
}

output "cluster_security_group_id" {
  description = "Cluster security group ID."
  value       = module.this.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Node shared security group ID."
  value       = module.this.node_security_group_id
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN used for IRSA."
  value       = module.this.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster."
  value       = module.this.cluster_oidc_issuer_url
}
