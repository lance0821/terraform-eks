output "vpc_id" {
  description = "ID of the created VPC."
  value       = module.this.vpc_id
}

output "private_subnets" {
  description = "IDs of created private subnets."
  value       = module.this.private_subnets
}

output "public_subnets" {
  description = "IDs of created public subnets."
  value       = module.this.public_subnets
}

output "vpc_cidr_block" {
  description = "CIDR block of the created VPC."
  value       = module.this.vpc_cidr_block
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for NAT gateways (useful for allowlisting)."
  value       = module.this.nat_public_ips
}
