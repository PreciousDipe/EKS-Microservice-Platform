#!/usr/bin/env bash

set -euo pipefail

cat > terraform.tfvars <<'EOF'
region      = "eu-north-1"
environment = "shared"

pod_security_level = "baseline"
isolate_namespaces = true

environments = {
  dev = {
    resource_quota = {
      "requests.cpu"           = "2"
      "requests.memory"        = "4Gi"
      "limits.cpu"             = "8"
      "limits.memory"          = "8Gi"
      "pods"                   = "30"
      "services.loadbalancers" = "2"
      "persistentvolumeclaims" = "10"
    }
  }
  staging = {
    resource_quota = {
      "requests.cpu"           = "2"
      "requests.memory"        = "4Gi"
      "limits.cpu"             = "8"
      "limits.memory"          = "8Gi"
      "pods"                   = "30"
      "services.loadbalancers" = "2"
      "persistentvolumeclaims" = "10"
    }
  }
  prod = {
    resource_quota = {
      "requests.cpu"           = "4"
      "requests.memory"        = "8Gi"
      "limits.cpu"             = "16"
      "limits.memory"          = "16Gi"
      "pods"                   = "60"
      "services.loadbalancers" = "4"
      "persistentvolumeclaims" = "20"
    }
    default_request = { cpu = "200m", memory = "256Mi" }
    default_limit   = { cpu = "1", memory = "1Gi" }
  }
}
EOF

echo "Generated terraform.tfvars for platform:"
cat terraform.tfvars
