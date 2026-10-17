variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name. One cluster serves every environment, separated by namespace"
  type        = string
  default     = "shared"
  validation {
    condition     = var.environment == "shared"
    error_message = "environment must be shared for the eks layer."
  }
}

variable "state_bucket" {
  description = "S3 bucket holding the Terraform state files (used to read upstream layers)"
  type        = string
  default     = "eks-platform-project-tfstate"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version, e.g. 1.36"
  type        = string
}

variable "support_type" {
  description = "STANDARD or EXTENDED version support"
  type        = string
  default     = "STANDARD"
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API endpoint publicly"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_groups" {
  description = "Managed node groups keyed by name"
  type = map(object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    disk_size      = optional(number, 50)
    min_size       = number
    max_size       = number
    desired_size   = number
    labels         = optional(map(string), {})
  }))
}

variable "addon_versions" {
  description = "Optional pinned versions for managed add-ons, keyed by add-on name"
  type        = map(string)
  default     = {}
}

variable "enable_network_policy" {
  description = "Enable NetworkPolicy enforcement in the VPC CNI"
  type        = bool
  default     = true
}

variable "admin_principal_arns" {
  description = "Extra IAM principals granted cluster-admin (e.g. the GitHub Actions deploy role)"
  type        = list(string)
  default     = []
}

variable "namespace_access" {
  description = "Namespace-scoped access entries for teams"
  type = map(object({
    principal_arn = string
    namespaces    = list(string)
    policy        = optional(string, "AmazonEKSEditPolicy")
  }))
  default = {}
}

variable "enable_aws_load_balancer_controller" {
  description = "Create IAM for the AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller_version" {
  description = "AWS Load Balancer Controller release tag (v3.x.y)"
  type        = string
  default     = "v3.5.0"
}
