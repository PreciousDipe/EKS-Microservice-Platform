output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_version" {
  description = "Kubernetes version of the control plane"
  value       = aws_eks_cluster.this.version
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA certificate for the API endpoint"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "EKS-managed cluster security group, attached to the control plane and every managed node"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for IRSA"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL of the cluster"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_role_arn" {
  description = "IAM role used by the managed node groups"
  value       = aws_iam_role.node.arn
}

output "node_group_names" {
  description = "Map of node group key to the generated node group name"
  value       = { for k, ng in aws_eks_node_group.this : k => ng.node_group_name }
}

output "kms_key_arn" {
  description = "KMS key used for secrets envelope encryption"
  value       = aws_kms_key.eks.arn
}

output "aws_load_balancer_controller_version" {
  description = "AWS Load Balancer Controller version the IAM policy was built for (null when disabled)"
  value       = var.enable_aws_load_balancer_controller ? var.aws_load_balancer_controller_version : null
}
