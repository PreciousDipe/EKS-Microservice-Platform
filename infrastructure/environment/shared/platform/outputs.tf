output "namespaces" {
  description = "Environment namespaces created in the cluster"
  value       = module.platform.namespaces
}

output "default_storage_class" {
  description = "Name of the default StorageClass"
  value       = module.platform.default_storage_class
}

output "aws_load_balancer_controller_chart_version" {
  description = "Installed AWS Load Balancer Controller chart version"
  value       = module.platform.aws_load_balancer_controller_chart_version
}

output "cluster_issuer_name" {
  description = "Private-CA ClusterIssuer"
  value       = module.platform.cluster_issuer_name
}

output "gateway_class_name" {
  description = "GatewayClass of the shared Gateway"
  value       = module.platform.gateway_class_name
}

output "letsencrypt_issuer_name" {
  description = "Publicly trusted ClusterIssuer for app certificates"
  value       = module.platform.letsencrypt_issuer_name
}

output "shared_gateway" {
  description = "Gateway the application chart attaches to (gateway.name / gateway.namespace)"
  value       = module.platform.shared_gateway
}
