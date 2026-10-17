#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
OUT=$RESULTS/03-autoscaling.txt; : > "$OUT"

kubectl top pods -n "$NS" >/dev/null 2>&1 || fail "metrics-server isn't ready (kubectl top pods fails), so the HPA can't scale yet"

log "Environment: $NS ($GATEWAY)"
log "Before:"; kubectl -n "$NS" get hpa product-service-hpa | tee -a "$OUT"
log "Starting k6 (ramps to 200 req/s, holds 2 min, stops)"; k6 tests/k6/hpa-load.js > "$RESULTS/03-k6-output.txt" 2>&1 & K6=$!

for i in $(seq 1 28); do
  sleep 15
  log "t+$((i*15))s $(kubectl -n "$NS" get hpa product-service-hpa --no-headers | awk '{print "cpu:", $4, "replicas=" $7}')"
done
wait $K6

grep -E "http_reqs|http_req_failed" "$RESULTS/03-k6-output.txt" | tee -a "$OUT"
kubectl -n "$NS" describe hpa product-service-hpa | grep SuccessfulRescale | tee -a "$OUT"
grep -q "New size" "$OUT" && pass "the HPA scaled product-service with the load" || fail "no rescale events"
