terraform {
  backend "s3" {
    bucket       = "eks-platform-project-tfstate"
    key          = "shared/platform/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }
}
