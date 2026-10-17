terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws  = { source = "hashicorp/aws", version = "~> 5.0" }
    tls  = { source = "hashicorp/tls", version = "~> 4.0" }
    http = { source = "hashicorp/http", version = "~> 3.4" }
  }
}

provider "aws" { region = var.region }

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "terraform-multi-environment"
    Layer       = "eks"
  }
}

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "shared/networking/terraform.tfstate"
    region = var.region
  }
}

module "eks" {
  source                 = "../../../modules/eks"
  cluster_name           = var.cluster_name
  kubernetes_version     = var.kubernetes_version
  support_type           = var.support_type
  vpc_id                 = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnet_ids     = values(data.terraform_remote_state.networking.outputs.private_subnet_ids)
  endpoint_public_access = var.endpoint_public_access
  public_access_cidrs    = var.public_access_cidrs
  node_groups            = var.node_groups
  addon_versions         = var.addon_versions
  enable_network_policy  = var.enable_network_policy
  admin_principal_arns   = var.admin_principal_arns
  namespace_access       = var.namespace_access
  dns_zone_arn           = try(data.terraform_remote_state.networking.outputs.dns_zone_arn, null)

  enable_aws_load_balancer_controller  = var.enable_aws_load_balancer_controller
  aws_load_balancer_controller_version = var.aws_load_balancer_controller_version

  tags = local.common_tags
}
