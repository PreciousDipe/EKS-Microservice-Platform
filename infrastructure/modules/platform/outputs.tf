output "namespaces" {
  description = "Environment namespaces created in the cluster"
  value       = [for ns in kubernetes_namespace_v1.env : ns.metadata[0].name]
}

output "default_storage_class" {
  description = "Name of the default StorageClass"
  value       = kubernetes_storage_class_v1.gp3.metadata[0].name
}

output "aws_load_balancer_controller_chart_version" {
  description = "Installed AWS Load Balancer Controller chart version (null when not installed)"
  value       = one(helm_release.aws_load_balancer_controller[*].version)
}

output "cluster_issuer_name" {
  description = "ClusterIssuer apps reference for TLS certificates (null when cert-manager is not installed)"
  value       = var.cert_manager_version == null ? null : var.cluster_issuer_name
}

output "gateway_class_name" {
  description = "GatewayClass provided by NGINX Gateway Fabric (null when not installed)"
  value       = var.nginx_gateway_fabric_version == null ? null : "nginx"
}

output "letsencrypt_issuer_name" {
  description = "Publicly trusted ClusterIssuer (null when DNS is not configured)"
  value       = one(kubectl_manifest.letsencrypt_issuer[*].name)
}

output "shared_gateway" {
  description = "Gateway every environment's HTTPRoutes attach to (null when not created)"
  value       = local.shared_gateway ? { name = var.shared_gateway_name, namespace = var.shared_gateway_namespace } : null
}
