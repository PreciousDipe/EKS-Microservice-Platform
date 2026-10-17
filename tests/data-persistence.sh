#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
OUT=$RESULTS/04-data-persistence.txt; : > "$OUT"
POD=postgres-statefulset-0; PVC=data-postgres-statefulset-0

# Run SQL inside the database pod, with the credentials it already has.
q() { kubectl -n "$NS" exec $POD -- sh -c "psql -X -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -At -c \"$1\""; }
state() { echo "$(q "SELECT count(*) || ' orders, newest id ' || coalesce(max(id),0) FROM orders")"; }

log "Environment: $NS ($GATEWAY)"
log "Create an order through the Gateway:"; api -X POST $GATEWAY/api/orders -d '{"productId":1,"quantity":3}' | tee -a "$OUT"; echo | tee -a "$OUT"

B=$(state); PB=$(kubectl -n "$NS" get pvc $PVC -o jsonpath='{.metadata.uid}'); OB=$(kubectl -n "$NS" get pod $POD -o jsonpath='{.metadata.uid}')
log "Before: $B | PVC uid=$PB | pod uid=$OB"

log "kubectl delete pod $POD"; kubectl -n "$NS" delete pod $POD | tee -a "$OUT"
kubectl -n "$NS" wait --for=condition=Ready pod/$POD --timeout=300s | tee -a "$OUT"

A=$(state); PA=$(kubectl -n "$NS" get pvc $PVC -o jsonpath='{.metadata.uid}'); OA=$(kubectl -n "$NS" get pod $POD -o jsonpath='{.metadata.uid}')
log "After:  $A | PVC uid=$PA | pod uid=$OA"

sleep 5; log "Orders through the API: $(api $GATEWAY/api/orders | head -c 200)"
[ "$B" = "$A" ] && [ "$PB" = "$PA" ] && [ "$OB" != "$OA" ] \
  && pass "new pod, same PVC, data survived" || fail "data or volume changed"
