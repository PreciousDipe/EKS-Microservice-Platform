variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  validation {
    # Kept short because IAM name_prefix values (e.g. "<name>-ebs-csi-") are capped at 38 characters
    condition     = can(regex("^[a-z][a-z0-9-]{1,27}$", var.cluster_name))
    error_message = "cluster_name must be 2-28 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes minor version for the control plane, e.g. 1.36"
  type        = string
  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must look like 1.36."
  }
}

variable "support_type" {
  description = "STANDARD auto-upgrades at end of standard support; EXTENDED keeps the version longer at extra hourly cost"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "EXTENDED"], var.support_type)
    error_message = "support_type must be STANDARD or EXTENDED."
  }
}

variable "vpc_id" {
  description = "VPC the cluster runs in"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs (at least two AZs) for the control plane ENIs and worker nodes"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "EKS needs subnets in at least two availability zones."
  }
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API endpoint publicly (needed for kubectl from your laptop / GitHub-hosted runners)"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "Control plane log types sent to CloudWatch"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "log_retention_days" {
  description = "Retention for the control plane CloudWatch log group"
  type        = number
  default     = 30
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
  validation {
    condition     = alltrue([for ng in values(var.node_groups) : contains(["ON_DEMAND", "SPOT"], ng.capacity_type)])
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
  validation {
    condition     = alltrue([for ng in values(var.node_groups) : ng.min_size <= ng.desired_size && ng.desired_size <= ng.max_size])
    error_message = "Each node group needs min_size <= desired_size <= max_size."
  }
}

variable "addon_versions" {
  description = "Pin managed add-on versions by add-on name; anything not listed uses the EKS default for the cluster version"
  type        = map(string)
  default     = {}
}

variable "enable_network_policy" {
  description = "Enable the VPC CNI network policy agent so NetworkPolicy objects are enforced"
  type        = bool
  default     = true
}

variable "enable_aws_load_balancer_controller" {
  description = "Create the IAM role + Pod Identity association for the AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller_version" {
  description = "AWS Load Balancer Controller release tag; its IAM policy is downloaded from this tag"
  type        = string
  default     = "v3.5.0"
  validation {
    condition     = can(regex("^v3\\.[0-9]+\\.[0-9]+$", var.aws_load_balancer_controller_version))
    error_message = "aws_load_balancer_controller_version must be a v3.x.y tag, e.g. v3.5.0."
  }
}

variable "admin_principal_arns" {
  description = "IAM role/user ARNs granted cluster-admin. Do NOT include the identity that creates the cluster (it is already admin)"
  type        = list(string)
  default     = []
}

variable "namespace_access" {
  description = "Namespace-scoped access entries, e.g. { dev-team = { principal_arn = \"...\", namespaces = [\"dev\"] } }"
  type = map(object({
    principal_arn = string
    namespaces    = list(string)
    policy        = optional(string, "AmazonEKSEditPolicy")
  }))
  default = {}
  validation {
    condition     = alltrue([for a in values(var.namespace_access) : contains(["AmazonEKSAdminPolicy", "AmazonEKSEditPolicy", "AmazonEKSViewPolicy"], a.policy)])
    error_message = "policy must be AmazonEKSAdminPolicy, AmazonEKSEditPolicy or AmazonEKSViewPolicy."
  }
}

variable "tags" {
  description = "Common tags applied to every resource in this module"
  type        = map(string)
  default     = {}
}

variable "dns_zone_arn" {
  description = "Route 53 hosted zone external-dns and cert-manager may manage (null = no DNS roles)"
  type        = string
  default     = null
}
