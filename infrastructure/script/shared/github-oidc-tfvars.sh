#!/usr/bin/env bash

set -euo pipefail

cat > terraform.tfvars <<'EOF'
region      = "eu-north-1"
environment = "shared"

github_repository    = "PreciousDipe/EKS-Microservice-Platform"
github_environments  = ["develop", "staging", "production"]
role_name            = "github-actions-eks-platform"
create_oidc_provider = true
EOF

echo "Generated terraform.tfvars for github-oidc:"
cat terraform.tfvars
