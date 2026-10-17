terraform {
  backend "s3" {
    bucket       = "eks-platform-project-tfstate"
    key          = "shared/eks/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }
}
