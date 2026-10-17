variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region of the cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC the cluster runs in (passed to the load balancer controller)"
  type        = string
}

variable "environments" {
  description = "Environments to create as namespaces, keyed by namespace name"
  type = map(object({
    resource_quota  = map(string)
    default_request = optional(map(string), { cpu = "100m", memory = "128Mi" })
    default_limit   = optional(map(string), { cpu = "500m", memory = "512Mi" })
  }))
  validation {
    condition     = alltrue([for name in keys(var.environments) : contains(["dev", "staging", "prod"], name)])
    error_message = "environment namespaces must be dev, staging or prod."
  }
}

variable "pod_security_level" {
  description = "Pod Security Admission level enforced in environment namespaces (privileged, baseline, restricted)"
  type        = string
  default     = "baseline"
  validation {
    condition     = contains(["privileged", "baseline", "restricted"], var.pod_security_level)
    error_message = "pod_security_level must be privileged, baseline or restricted."
  }
}

variable "isolate_namespaces" {
  description = "Block ingress between environment namespaces with a NetworkPolicy"
  type        = bool
  default     = true
}

variable "load_balancer_source_cidrs" {
  description = "CIDRs allowed into environment namespaces besides pods (normally the public subnets where ALBs/NLBs live)"
  type        = list(string)
  default     = []
}

variable "aws_load_balancer_controller_version" {
  description = "Controller version (v3.x.y) to install, or null to skip the Helm release"
  type        = string
  default     = null
}

variable "metrics_server_chart_version" {
  description = "metrics-server Helm chart version (needed by HorizontalPodAutoscalers), or null to skip"
  type        = string
  default     = "3.14.0"
}

variable "cert_manager_version" {
  description = "cert-manager Helm chart version, or null to skip cert-manager and the cluster issuers"
  type        = string
  default     = "v1.21.2"
}

variable "cluster_issuer_name" {
  description = "Name of the shared private-CA ClusterIssuer apps reference for TLS certificates"
  type        = string
  default     = "platform-ca"
}

variable "nginx_gateway_fabric_version" {
  description = "NGINX Gateway Fabric chart version, or null to skip it and the Gateway API CRDs"
  type        = string
  default     = "2.7.2"
}

variable "gateway_api_version" {
  description = "Gateway API CRD release to install (must match what NGINX Gateway Fabric supports)"
  type        = string
  default     = "v1.6.1"
}

variable "dns_zone_name" {
  description = "Delegated DNS zone for app hostnames (null = no external-dns / Let's Encrypt)"
  type        = string
  default     = null
}

variable "dns_zone_id" {
  description = "Route 53 hosted zone ID of dns_zone_name"
  type        = string
  default     = null
}

variable "acme_email" {
  description = "Email registered with Let's Encrypt (set via TF_VAR_acme_email / ACME_EMAIL)"
  type        = string
  default     = ""
}

variable "external_dns_chart_version" {
  description = "external-dns Helm chart version"
  type        = string
  default     = "1.22.0"
}

variable "shared_gateway_name" {
  description = "Name of the Gateway shared by all environments (application charts attach HTTPRoutes to it)"
  type        = string
  default     = "shared-gateway"
}

variable "shared_gateway_namespace" {
  description = "Namespace of the shared Gateway"
  type        = string
  default     = "gateway"
}
