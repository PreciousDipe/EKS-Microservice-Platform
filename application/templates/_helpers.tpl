{{/*
Reusable snippets. A template calls one with:  {{ include "shop.<name>" <context> }}
*/}}

{{/* Labels on every object: who made it (Helm), which release, which chart version. */}}
{{- define "shop.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{/* Labels for one component. Usage: include "shop.componentLabels" (dict "name" "frontend" "partOf" "app" "tier" "frontend" "ctx" $) */}}
{{- define "shop.componentLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/part-of: {{ .partOf }}
tier: {{ .tier }}
{{ include "shop.labels" .ctx }}
{{- end }}

{{/* Pod security context. Usage: include "shop.podSecurity" (dict "uid" 1001 "gid" 1001 "fsGroup" 0) */}}
{{- define "shop.podSecurity" -}}
runAsNonRoot: true
runAsUser: {{ .uid }}
runAsGroup: {{ .gid }}
{{- if .fsGroup }}
fsGroup: {{ .fsGroup }}
{{- end }}
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{/* Container security context. Pass true for a read-only root filesystem. */}}
{{- define "shop.containerSecurity" -}}
allowPrivilegeEscalation: false
{{- if . }}
readOnlyRootFilesystem: true
{{- end }}
capabilities:
  drop:
    - ALL
{{- end }}

{{/* Prefer one replica per node. Usage: include "shop.antiAffinity" "frontend" */}}
{{- define "shop.antiAffinity" -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: {{ . }}
{{- end }}

{{/* Rolling update: one extra pod at a time, never below the desired count. */}}
{{- define "shop.rollingUpdate" -}}
type: RollingUpdate
rollingUpdate:
  maxSurge: 1
  maxUnavailable: 0
{{- end }}

{{/* HPA behaviour shared by every autoscaler. */}}
{{- define "shop.hpaBehavior" -}}
scaleUp:
  stabilizationWindowSeconds: 0
  policies:
    - type: Pods
      value: {{ .Values.hpaBehavior.scaleUpPods }}
      periodSeconds: {{ .Values.hpaBehavior.scaleUpPeriodSeconds }}
scaleDown:
  stabilizationWindowSeconds: {{ .Values.hpaBehavior.scaleDownStabilizationSeconds }}
  policies:
    - type: Pods
      value: {{ .Values.hpaBehavior.scaleDownPods }}
      periodSeconds: {{ .Values.hpaBehavior.scaleDownPeriodSeconds }}
{{- end }}

{{/* Service image from the pipeline. Usage: include "shop.appImage" (dict "image" .Values.images.productService "ctx" $) */}}
{{- define "shop.appImage" -}}
{{- $registry := required "images.registry is required (set by the pipeline)" .ctx.Values.images.registry -}}
{{- $tag := required (printf "images tag for %s is required (set by the pipeline)" .image.repository) .image.tag -}}
{{ printf "%s/%s:%s" (trimSuffix "/" $registry) .image.repository $tag }}
{{- end }}

{{/* PGUSER / PGPASSWORD env entries from the Secret. */}}
{{- define "shop.dbEnv" -}}
- name: PGUSER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: POSTGRES_USER
- name: PGPASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: POSTGRES_PASSWORD
{{- end }}

{{/* Full DNS names of the data tier. */}}
{{- define "shop.postgresHost" -}}
postgres-svc.{{ .Release.Namespace }}.svc.cluster.local
{{- end }}
{{- define "shop.redisHost" -}}
redis-svc.{{ .Release.Namespace }}.svc.cluster.local
{{- end }}

{{/*
Checksum of the backend configuration. It goes into the pod template as an
annotation, so changing a value and running "helm upgrade" rolls the pods
automatically (environment variables are only read when a pod starts).
*/}}
{{- define "shop.backendChecksum" -}}
checksum/config: {{ include (print .Template.BasePath "/backend/configmap.yaml") . | sha256sum }}
checksum/secret: {{ include (print .Template.BasePath "/secrets.yaml") . | sha256sum }}
{{- end }}

{{/* Gateway hostname: <namespace>.<gateway.domain>, e.g. dev.microservice-shop.preciousdipe.name.ng */}}
{{- define "shop.gatewayHost" -}}
{{- printf "%s.%s" .Release.Namespace (required "gateway.domain is required" .Values.gateway.domain) }}
{{- end }}

{{/* Ingress peer: the shared Gateway's nginx pods in the platform's gateway namespace */}}
{{- define "shop.gatewayPeer" -}}
- namespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: {{ .Values.gateway.namespace }}
  podSelector:
    matchLabels:
      gateway.networking.k8s.io/gateway-name: {{ .Values.gateway.name }}
{{- end }}
