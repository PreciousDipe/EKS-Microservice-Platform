#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
NEW_TAG="${1:-}"; OUT=$RESULTS/01-zero-downtime.txt; : > "$OUT"

log "Environment: $NS ($GATEWAY)"
log "Before:"; kubectl -n "$NS" get deploy product-service -o wide | tee -a "$OUT"
log "Starting k6 (50 req/s, 90 s)"; k6 tests/k6/zero-downtime.js > "$RESULTS/01-k6-output.txt" 2>&1 & K6=$!
sleep 15

if [ -n "$NEW_TAG" ]; then
  # Same repository as the running image, new tag (leaves the Deployment out of sync with Helm).
  REPO=$(kubectl -n "$NS" get deploy product-service -o jsonpath='{.spec.template.spec.containers[0].image}'); REPO="${REPO%:*}"
  log "kubectl set image deployment/product-service product-service=${REPO}:${NEW_TAG}"
  kubectl -n "$NS" set image deployment/product-service product-service="${REPO}:${NEW_TAG}" | tee -a "$OUT"
else
  log "kubectl rollout restart deployment/product-service"
  kubectl -n "$NS" rollout restart deployment/product-service | tee -a "$OUT"
fi
kubectl -n "$NS" rollout status deployment/product-service --timeout=300s | tee -a "$OUT"
log "After:"; kubectl -n "$NS" get deploy product-service -o wide | tee -a "$OUT"

wait $K6; RC=$?
grep -E "errors_5xx|http_req_failed|http_reqs" "$RESULTS/01-k6-output.txt" | tee -a "$OUT"
[ -n "$NEW_TAG" ] && log "To go back to the Helm-managed image: helm rollback microservice-shop -n $NS"
[ $RC -eq 0 ] && pass "no 5xx or failed requests during the rollout" || fail "k6 exit $RC, see $RESULTS/01-k6-output.txt"
