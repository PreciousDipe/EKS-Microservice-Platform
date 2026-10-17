set -uo pipefail
NS="${NS:-dev}"
DOMAIN="${DOMAIN:-microservice-shop.preciousdipe.name.ng}"
HOST="$NS.$DOMAIN"
GATEWAY="https://$HOST"
K6_IMAGE="${K6_IMAGE:-grafana/k6:2.3.0}"
RESULTS="${RESULTS:-results}"
mkdir -p "$RESULTS"

# Print with a timestamp and append to the result file ($OUT, set by each script).
log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$OUT"; }

# curl through the environment's Gateway (public DNS + Let's Encrypt certificate).
api() { curl -s -H "Content-Type: application/json" "$@"; }

# Run a k6 script in Docker against the environment's Gateway.
k6() { docker run --rm -i -e BASE_URL="$GATEWAY" "$K6_IMAGE" run - < "$1"; }

pass() { log "RESULT: PASS - $*"; }
fail() { log "RESULT: FAIL - $*"; exit 1; }
