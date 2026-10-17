variable "region" {
  description = "AWS region for the provider (IAM itself is global)"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name of this layer"
  type        = string
  default     = "shared"
  validation {
    condition     = var.environment == "shared"
    error_message = "environment must be shared for the github-oidc layer."
  }
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the role, as owner/name"
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must look like owner/name, e.g. preciousdipe/EKS-Microservice-Platform."
  }
}

variable "github_environments" {
  description = "GitHub environments whose jobs may assume the role"
  type        = list(string)
  default     = ["develop", "staging", "production"]
}

variable "role_name" {
  description = "Name of the IAM role GitHub Actions assumes"
  type        = string
  default     = "github-actions-eks-platform"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider; set false if the account already has one"
  type        = bool
  default     = true
}

variable "github_owner_id" {
  description = "Numeric ID of the repository owner (GitHub API: .owner.id), used in the immutable-ID subject claim"
  type        = number
}

variable "github_repository_id" {
  description = "Numeric ID of the repository (GitHub API: .id), used in the immutable-ID subject claim"
  type        = number
}
