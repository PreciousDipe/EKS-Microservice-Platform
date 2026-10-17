terraform {
  backend "s3" {
    bucket       = "eks-platform-project-tfstate"
    key          = "shared/networking/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }
}
