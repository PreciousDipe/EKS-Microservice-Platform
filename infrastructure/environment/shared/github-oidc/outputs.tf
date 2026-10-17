output "role_arn" {
  description = "Store as the AWS_ROLE_TO_ASSUME GitHub secret and add to admin_principal_arns in eks-tfvars.sh"
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "GitHub Actions OIDC provider"
  value       = local.oidc_provider_arn
}
