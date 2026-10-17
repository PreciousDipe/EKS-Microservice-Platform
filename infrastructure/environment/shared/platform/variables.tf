variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name of this layer (the namespaces themselves come from var.environments)"
  type        = string
  default     = "shared"
  validation {
    condition     = var.environment == "shared"
    error_message = "environment must be shared for the platform layer."
  }
}

variable "state_bucket" {
  description = "S3 bucket holding the Terraform state files (used to read upstream layers)"
  type        = string
  default     = "eks-platform-project-tfstate"
}

variable "environments" {
  description = "Environment namespaces with their resource quotas and container defaults"
  type = map(object({
    resource_quota  = map(string)
    default_request = optional(map(string), { cpu = "100m", memory = "128Mi" })
    default_limit   = optional(map(string), { cpu = "500m", memory = "512Mi" })
  }))
}

variable "pod_security_level" {
  description = "Pod Security Admission level enforced in environment namespaces"
  type        = string
  default     = "baseline"
}

variable "isolate_namespaces" {
  description = "Block traffic between environment namespaces with a NetworkPolicy"
  type        = bool
  default     = true
}

variable "acme_email" {
  description = "Email registered with Let's Encrypt (certificate expiry notices)"
  type        = string
  default     = ""
}
