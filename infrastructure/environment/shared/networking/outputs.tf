output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Map of AZ to public subnet ID"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Map of AZ to private subnet ID"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = var.public_subnet_cidrs
}

output "dns_zone_name" {
  description = "Delegated DNS zone for the platform (null when not configured)"
  value       = one(aws_route53_zone.this[*].name)
}

output "dns_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = one(aws_route53_zone.this[*].zone_id)
}

output "dns_zone_arn" {
  description = "Route 53 hosted zone ARN"
  value       = one(aws_route53_zone.this[*].arn)
}

output "dns_name_servers" {
  description = "Add these as the NS record for dns_zone_name in the parent domain's account"
  value       = one(aws_route53_zone.this[*].name_servers)
}
