output "release_name" {
  description = "Helm release name."
  value       = var.create ? helm_release.this[0].name : null
}

output "release_namespace" {
  description = "Namespace of the Helm release."
  value       = var.create ? helm_release.this[0].namespace : null
}

output "release_status" {
  description = "Status of the Helm release."
  value       = var.create ? helm_release.this[0].status : null
}

output "release_version" {
  description = "Chart version deployed."
  value       = var.create ? helm_release.this[0].version : null
}

output "release_metadata" {
  description = "Release metadata block."
  value       = var.create ? helm_release.this[0].metadata : null
}

output "irsa_role_arn" {
  description = "IRSA IAM role ARN, if created."
  value       = var.create && var.create_irsa_role ? module.irsa[0].arn : null
}

output "irsa_role_name" {
  description = "IRSA IAM role name, if created."
  value       = var.create && var.create_irsa_role ? module.irsa[0].name : null
}
