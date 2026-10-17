#!/usr/bin/env bash

set -euo pipefail

cat > terraform.tfvars <<'EOF'
region      = "eu-north-1"
environment = "shared"
name_prefix = "platform-project"

vpc_cidr             = "10.0.0.0/16"
az_count             = 2
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.32.0/19", "10.0.64.0/19"]
enable_nat_gateway   = true

dns_zone_name = "microservice-shop.preciousdipe.name.ng"
EOF

echo "Generated terraform.tfvars for networking:"
cat terraform.tfvars
