terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 3.3" }
    helm       = { source = "hashicorp/helm", version = "~> 3.3" }
    http       = { source = "hashicorp/http", version = "~> 3.4" }
    kubectl    = { source = "alekc/kubectl", version = "~> 2.4" }
  }
}

provider "aws" { region = var.region }

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "shared/networking/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "shared/eks/terraform.tfstate"
    region = var.region
  }
}

locals {
  cluster_name = data.terraform_remote_state.eks.outputs.cluster_name
  cluster = {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = local.cluster.host
  cluster_ca_certificate = local.cluster.cluster_ca_certificate
  token                  = local.cluster.token
}

provider "helm" {
  kubernetes = local.cluster
}

provider "kubectl" {
  host                   = local.cluster.host
  cluster_ca_certificate = local.cluster.cluster_ca_certificate
  token                  = local.cluster.token
  load_config_file       = false
}

module "platform" {
  source                     = "../../../modules/platform"
  cluster_name               = local.cluster_name
  region                     = var.region
  vpc_id                     = data.terraform_remote_state.networking.outputs.vpc_id
  environments               = var.environments
  pod_security_level         = var.pod_security_level
  isolate_namespaces         = var.isolate_namespaces
  load_balancer_source_cidrs = data.terraform_remote_state.networking.outputs.public_subnet_cidrs
  dns_zone_name              = try(data.terraform_remote_state.networking.outputs.dns_zone_name, null)
  dns_zone_id                = try(data.terraform_remote_state.networking.outputs.dns_zone_id, null)
  acme_email                 = var.acme_email

  aws_load_balancer_controller_version = data.terraform_remote_state.eks.outputs.aws_load_balancer_controller_version
}
