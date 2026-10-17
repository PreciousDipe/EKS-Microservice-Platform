variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name. The cluster VPC is shared by all environments"
  type        = string
  default     = "shared"
  validation {
    condition     = var.environment == "shared"
    error_message = "environment must be shared for the cluster networking layer."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (load balancers, NAT), one per AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (nodes and pod IPs), one per AZ"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to provision a NAT Gateway for private subnet egress (required: nodes pull images through it)"
  type        = bool
  default     = true
}

variable "dns_zone_name" {
  description = "Subdomain delegated to this account for the platform (empty = no hosted zone)"
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Prefix for resource names, e.g. platform-project-vpc"
  type        = string
  default     = "platform-project"
}
