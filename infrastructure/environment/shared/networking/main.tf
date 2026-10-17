terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = var.region }

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "terraform-multi-environment"
    Layer       = "networking"
  }
}

module "networking" {
  source               = "../../../modules/networking"
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  name_prefix          = var.name_prefix
  tags                 = local.common_tags

  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
}

# Delegated from the parent domain's account with an NS record (see output dns_name_servers)
resource "aws_route53_zone" "this" {
  count = var.dns_zone_name == "" ? 0 : 1

  name          = var.dns_zone_name
  force_destroy = true

  tags = merge(local.common_tags, { Name = var.dns_zone_name })
}
