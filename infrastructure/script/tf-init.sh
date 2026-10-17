#!/usr/bin/env bash
# AWS backend initialization script for a lifecycle layer in a given environment.
#
#   bash script/tf-init.sh <env> <layer>
#   e.g.  bash script/tf-init.sh shared networking
#         bash script/tf-init.sh shared eks
#
# Then run terraform commands pointing to environment/<env>/<layer>/ as usual.
#!/usr/bin/env bash
# AWS backend initialization script for a lifecycle layer in a given environment.
set -euo pipefail

env="${1:?usage: tf-init.sh <env> <layer>}"
layer="${2:?usage: tf-init.sh <env> <layer>}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

# Ensure the targeted infrastructure layer directory exists
[ -d "$repo_root/environment/$env/$layer" ] || { echo "❌ No such layer directory: environment/$env/$layer" >&2; exit 1; }

echo "🔄 Regenerating variables via script/${env}/${layer}-tfvars.sh..."
# Regenerate this layer's tfvars for the target env, then move it cleanly to the layer execution folder
( 
  cd "$repo_root" 
  bash "script/${env}/${layer}-tfvars.sh" 
  mv terraform.tfvars "environment/$env/$layer/terraform.tfvars" 
)

echo "⚙️  Initializing Terraform state for layer [$layer] in environment [$env]..."
# Run init natively since the bucket details are already hardcoded inside backend.tf
terraform -chdir="$repo_root/environment/$env/$layer" init -reconfigure -input=false

echo
echo "🏁 Successfully initialized environment/$env/$layer."
echo "👉 To preview changes run:  terraform -chdir=environment/$env/$layer plan"
