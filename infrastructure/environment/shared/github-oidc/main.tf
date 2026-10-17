terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = var.region }

data "aws_partition" "current" {}

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "terraform-multi-environment"
    Layer       = "github-oidc"
  }

  github_oidc_url = "token.actions.githubusercontent.com"

  github_owner = split("/", var.github_repository)[0]
  github_repo  = split("/", var.github_repository)[1]

  # GitHub sends either the immutable-ID subject (owner@id/repo@id) or the classic one (owner/repo)
  trusted_subjects = concat(
    [for env in var.github_environments : "repo:${local.github_owner}@${var.github_owner_id}/${local.github_repo}@${var.github_repository_id}:environment:${env}"],
    [for env in var.github_environments : "repo:${var.github_repository}:environment:${env}"],
  )

  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://${local.github_oidc_url}"
  client_id_list = ["sts.amazonaws.com"]

  tags = merge(local.common_tags, { Name = "github-actions" })
}

# Use the account's existing GitHub provider (only one is allowed per account)
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://${local.github_oidc_url}"
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only jobs in this repository that run in one of these GitHub environments
    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_url}:sub"
      values   = local.trusted_subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = var.role_name
  description          = "Assumed by GitHub Actions in ${var.github_repository} to plan/apply the EKS platform and deploy apps"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 7200

  tags = merge(local.common_tags, { Name = var.role_name })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}
