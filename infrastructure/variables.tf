variable "region" {
  type        = string
  description = "The AWS region where the backend resources will be created."
  default     = "eu-north-1"
}

variable "state_bucket_name" {
  type        = string
  description = "The globally unique name for your Terraform remote state S3 bucket."
  default     = "eks-platform-project-tfstate"
}
