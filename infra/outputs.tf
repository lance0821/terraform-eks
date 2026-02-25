output "account_id" {
  description = "AWS account ID of the current caller."
  value       = data.aws_caller_identity.current.account_id
}

output "vpc_id" { value = module.vpc.vpc_id }
output "private_subnets" { value = module.vpc.private_subnets }
output "public_subnets" { value = module.vpc.public_subnets }

output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_version" { value = module.eks.cluster_version }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }