output "region" {
  description = "AWS region of the cluster"
  value       = var.region
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_version" {
  description = "Kubernetes version of the control plane"
  value       = module.eks.cluster_version
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA certificate for the API endpoint"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  description = "Cluster security group attached to all managed nodes (use it to let pods into RDS etc.)"
  value       = module.eks.cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "node_role_arn" {
  description = "IAM role used by the worker nodes"
  value       = module.eks.node_role_arn
}

output "aws_load_balancer_controller_version" {
  description = "AWS Load Balancer Controller version to install (null when disabled)"
  value       = module.eks.aws_load_balancer_controller_version
}

output "kubeconfig_command" {
  description = "Command that writes a kubeconfig entry for this cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
