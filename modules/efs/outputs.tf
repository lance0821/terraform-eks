output "file_system_id" {
  description = "EFS filesystem ID."
  value       = var.create ? aws_efs_file_system.this[0].id : null
}

output "file_system_arn" {
  description = "EFS filesystem ARN."
  value       = var.create ? aws_efs_file_system.this[0].arn : null
}

output "security_group_id" {
  description = "Security group ID for EFS mount targets."
  value       = var.create ? aws_security_group.this[0].id : null
}

output "mount_target_ids" {
  description = "Map of subnet ID to mount target ID."
  value       = var.create ? { for k, v in aws_efs_mount_target.this : k => v.id } : {}
}

output "file_system_dns_name" {
  description = "DNS name for the EFS filesystem."
  value       = var.create ? aws_efs_file_system.this[0].dns_name : null
}
