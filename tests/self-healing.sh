#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
OUT=$RESULTS/02-self-healing.txt; : > "$OUT"
SEL='app.kubernetes.io/name in (product-service,frontend)'

log "Environment: $NS ($GATEWAY)"
log "Before:"; kubectl -n "$NS" get pods -l "$SEL" -o wide | tee -a "$OUT"
V1=$(kubectl -n "$NS" get pods -l app.kubernetes.io/name=product-service -o jsonpath='{.items[0].metadata.name}')
V2=$(kubectl -n "$NS" get pods -l app.kubernetes.io/name=frontend -o jsonpath='{.items[0].metadata.name}')

log "kubectl delete pod $V1 $V2"; kubectl -n "$NS" delete pod "$V1" "$V2" --wait=false | tee -a "$OUT"
log "App while the pods are replaced: /api/products -> $(api $GATEWAY/api/products -o /dev/null -w '%{http_code}'), / -> $(api $GATEWAY/ -o /dev/null -w '%{http_code}')"

# Poll every 2 s until the victims are gone and 4 pods are Ready again (max 60 s).
for i in $(seq 1 30); do
  sleep 2; log "t+$((i*2))s"; kubectl -n "$NS" get pods -l "$SEL" | tee -a "$OUT"
  kubectl -n "$NS" get pods -l "$SEL" --no-headers | grep -qE "$V1|$V2" && continue
  [ "$(kubectl -n "$NS" get pods -l "$SEL" --no-headers | grep -c ' 1/1 ')" -ge 4 ] && break
done

kubectl -n "$NS" get events --sort-by=.lastTimestamp | grep SuccessfulCreate | tail -2 | tee -a "$OUT"
log "App still answering: $(api $GATEWAY/api/products -o /dev/null -w '%{http_code}')"
kubectl -n "$NS" wait --for=condition=Available deploy/product-service deploy/frontend --timeout=60s >/dev/null \
  && pass "deleted pods replaced, Deployments back to full strength" || fail "Deployments did not recover"
