variable "environment" {
  description = "Environment name (shared, dev, staging, prod) - used in tags/naming"
  type        = string
  validation {
    condition     = contains(["shared", "dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: shared, dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across"
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to provision a NAT Gateway for private subnet egress (cost lever: false in dev)"
  type        = bool
  default     = true
}

variable "internet_cidr_block" {
  description = "CIDR block used for default routes to the internet (via IGW / NAT)"
  type        = string
  default     = "0.0.0.0/0"
  validation {
    condition     = can(cidrhost(var.internet_cidr_block, 0))
    error_message = "internet_cidr_block must be a valid CIDR block."
  }
}

variable "public_subnet_tags" {
  description = "Extra tags for public subnets (e.g. kubernetes.io/role/elb for internet-facing load balancers)"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Extra tags for private subnets (e.g. kubernetes.io/role/internal-elb for internal load balancers)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags applied to every resource in this module"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for resource Name tags (defaults to the environment name)"
  type        = string
  default     = null
}
