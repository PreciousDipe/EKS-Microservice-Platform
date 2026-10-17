terraform {
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes" }
    helm       = { source = "hashicorp/helm" }
    http       = { source = "hashicorp/http" }
    kubectl    = { source = "alekc/kubectl" }
  }
}
