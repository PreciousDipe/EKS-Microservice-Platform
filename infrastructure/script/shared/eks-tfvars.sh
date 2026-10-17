#!/usr/bin/env bash

set -euo pipefail

cat > terraform.tfvars <<'EOF'
region      = "eu-north-1"
environment = "shared"

cluster_name       = "eks-microservice-platform"
kubernetes_version = "1.36"
support_type       = "STANDARD"

endpoint_public_access = true
public_access_cidrs    = ["0.0.0.0/0"]

# 4 x t3.medium = 68 pods, 8 vCPU (EC2 On-Demand quota must be >= 8)
node_groups = {
  general = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    ami_type       = "AL2023_x86_64_STANDARD"
    disk_size      = 50
    min_size       = 4
    max_size       = 4
    desired_size   = 4
  }
}

enable_network_policy = true

# GitHub Actions role from the github-oidc layer; never list the identity that creates the cluster
admin_principal_arns = ["arn:aws:iam::143977713038:role/github-actions-eks-platform"]

enable_aws_load_balancer_controller  = true
aws_load_balancer_controller_version = "v3.5.0"
EOF

echo "Generated terraform.tfvars for eks:"
cat terraform.tfvars
