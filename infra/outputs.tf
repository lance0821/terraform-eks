output "account_id" {
  description = "AWS account ID of the current caller."
  value       = data.aws_caller_identity.current.account_id
}
