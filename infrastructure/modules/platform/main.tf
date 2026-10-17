locals {
  environment_label = "platform/environment"
}

resource "kubernetes_namespace_v1" "env" {
  for_each = var.environments

  metadata {
    name = each.key

    labels = {
      (local.environment_label)            = each.key
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = var.pod_security_level
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_resource_quota_v1" "env" {
  for_each = var.environments

  metadata {
    name      = "${each.key}-quota"
    namespace = kubernetes_namespace_v1.env[each.key].metadata[0].name
  }

  spec {
    hard = each.value.resource_quota
  }
}

resource "kubernetes_limit_range_v1" "env" {
  for_each = var.environments

  metadata {
    name      = "${each.key}-defaults"
    namespace = kubernetes_namespace_v1.env[each.key].metadata[0].name
  }

  spec {
    limit {
      type            = "Container"
      default_request = each.value.default_request
      default         = each.value.default_limit
    }
  }
}

resource "kubernetes_network_policy_v1" "isolate" {
  for_each = { for name, env in var.environments : name => env if var.isolate_namespaces }

  metadata {
    name      = "isolate-environment"
    namespace = kubernetes_namespace_v1.env[each.key].metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {}
      }
    }

    ingress {
      from {
        namespace_selector {
          match_expressions {
            key      = local.environment_label
            operator = "DoesNotExist"
          }
        }
      }
    }

    dynamic "ingress" {
      for_each = length(var.load_balancer_source_cidrs) > 0 ? [1] : []

      content {
        dynamic "from" {
          for_each = var.load_balancer_source_cidrs

          content {
            ip_block {
              cidr = from.value
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  count = var.aws_load_balancer_controller_version == null ? 0 : 1

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = trimprefix(var.aws_load_balancer_controller_version, "v")
  namespace  = "kube-system"
  wait       = true
  timeout    = 600

  values = [yamlencode({
    clusterName = var.cluster_name
    region      = var.region
    vpcId       = var.vpc_id
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller" # matches the Pod Identity association in the eks layer
    }
  })]
}

resource "helm_release" "metrics_server" {
  count = var.metrics_server_chart_version == null ? 0 : 1

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version
  namespace  = "kube-system"
  wait       = true
}

resource "helm_release" "cert_manager" {
  count = var.cert_manager_version == null ? 0 : 1

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true
  timeout          = 600

  values = [yamlencode({
    crds = { enabled = true }
  })]
}

resource "kubectl_manifest" "issuer_bootstrap" {
  count = var.cert_manager_version == null ? 0 : 1

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = { name = "${var.cluster_issuer_name}-bootstrap" }
    spec       = { selfSigned = {} }
  })

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "issuer_root_ca" {
  count = var.cert_manager_version == null ? 0 : 1

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "${var.cluster_issuer_name}-root"
      namespace = "cert-manager"
    }
    spec = {
      isCA       = true
      commonName = "${var.cluster_issuer_name}-root"
      secretName = "${var.cluster_issuer_name}-root"
      duration   = "87600h"
      privateKey = { algorithm = "ECDSA", size = 256 }
      issuerRef = {
        name  = "${var.cluster_issuer_name}-bootstrap"
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
    }
  })

  depends_on = [kubectl_manifest.issuer_bootstrap]
}

resource "kubectl_manifest" "cluster_issuer" {
  count = var.cert_manager_version == null ? 0 : 1

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = { name = var.cluster_issuer_name }
    spec       = { ca = { secretName = "${var.cluster_issuer_name}-root" } }
  })

  depends_on = [kubectl_manifest.issuer_root_ca]
}

data "http" "gateway_api_crds" {
  count = var.nginx_gateway_fabric_version == null ? 0 : 1

  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_version}/standard-install.yaml"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Could not download Gateway API ${var.gateway_api_version} CRDs."
    }
  }
}

data "kubectl_file_documents" "gateway_api_crds" {
  count = var.nginx_gateway_fabric_version == null ? 0 : 1

  content = data.http.gateway_api_crds[0].response_body
}

resource "kubectl_manifest" "gateway_api_crds" {
  for_each = var.nginx_gateway_fabric_version == null ? {} : data.kubectl_file_documents.gateway_api_crds[0].manifests

  yaml_body         = each.value
  server_side_apply = true
  force_conflicts   = true
}

resource "helm_release" "nginx_gateway_fabric" {
  count = var.nginx_gateway_fabric_version == null ? 0 : 1

  name             = "ngf"
  repository       = "oci://ghcr.io/nginx/charts"
  chart            = "nginx-gateway-fabric"
  version          = var.nginx_gateway_fabric_version
  namespace        = "nginx-gateway"
  create_namespace = true
  wait             = true
  timeout          = 600

  values = [yamlencode({
    nginxGateway = { name = "nginx-gateway" } # pod label app.kubernetes.io/name used by app network policies
  })]

  depends_on = [kubectl_manifest.gateway_api_crds]
}

resource "helm_release" "external_dns" {
  count = var.dns_zone_name == null ? 0 : 1

  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.external_dns_chart_version
  namespace        = "external-dns"
  create_namespace = true
  wait             = true

  values = [yamlencode({
    provider      = { name = "aws" }
    sources       = ["gateway-httproute"]
    policy        = "sync"
    registry      = "txt"
    txtOwnerId    = var.cluster_name
    txtPrefix     = "extdns-"
    domainFilters = [var.dns_zone_name]
    serviceAccount = {
      create = true
      name   = "external-dns" # matches the Pod Identity association in the eks layer
    }
    env = [{ name = "AWS_DEFAULT_REGION", value = var.region }]
  })]
}

resource "kubectl_manifest" "letsencrypt_issuer" {
  count = var.dns_zone_name == null || var.cert_manager_version == null ? 0 : 1

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = { name = "letsencrypt" }
    spec = {
      acme = {
        server              = "https://acme-v02.api.letsencrypt.org/directory"
        email               = var.acme_email
        privateKeySecretRef = { name = "letsencrypt-account-key" }
        solvers = [{
          selector = { dnsZones = [var.dns_zone_name] }
          dns01 = {
            route53 = {
              region       = var.region
              hostedZoneID = var.dns_zone_id
            }
          }
        }]
      }
    }
  })

  lifecycle {
    precondition {
      condition     = can(regex("^[^@ ]+@[^@ ]+[.][^@ ]+$", var.acme_email))
      error_message = "Set the Let's Encrypt email: GitHub variable ACME_EMAIL in the pipeline, or export TF_VAR_acme_email on the CLI."
    }
  }

  depends_on = [helm_release.cert_manager]
}

locals {
  shared_gateway = var.dns_zone_name != null && var.nginx_gateway_fabric_version != null && var.cert_manager_version != null
  routes_from_environments = {
    namespaces = {
      from     = "Selector"
      selector = { matchExpressions = [{ key = local.environment_label, operator = "Exists" }] }
    }
  }
}

# One Gateway and one NLB for every environment; each namespace attaches its own HTTPRoute
resource "kubernetes_namespace_v1" "gateway" {
  count = local.shared_gateway ? 1 : 0

  metadata {
    name   = var.shared_gateway_namespace
    labels = { "app.kubernetes.io/managed-by" = "terraform" }
  }
}

resource "kubectl_manifest" "gateway_proxy" {
  count = local.shared_gateway ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "gateway.nginx.org/v1alpha2"
    kind       = "NginxProxy"
    metadata   = { name = "${var.shared_gateway_name}-proxy", namespace = kubernetes_namespace_v1.gateway[0].metadata[0].name }
    spec = {
      kubernetes = {
        service = {
          type                  = "LoadBalancer"
          loadBalancerClass     = "service.k8s.aws/nlb"
          externalTrafficPolicy = "Cluster"
          patches = [{
            type = "StrategicMerge"
            value = {
              metadata = {
                annotations = {
                  "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
                  "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
                }
              }
            }
          }]
        }
      }
    }
  })

  depends_on = [helm_release.nginx_gateway_fabric, helm_release.aws_load_balancer_controller]
}

resource "kubectl_manifest" "gateway_certificate" {
  count = local.shared_gateway ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata   = { name = "${var.shared_gateway_name}-tls", namespace = kubernetes_namespace_v1.gateway[0].metadata[0].name }
    spec = {
      secretName = "${var.shared_gateway_name}-tls"
      dnsNames   = ["*.${var.dns_zone_name}"]
      issuerRef  = { name = "letsencrypt", kind = "ClusterIssuer", group = "cert-manager.io" }
    }
  })

  depends_on = [kubectl_manifest.letsencrypt_issuer]
}

resource "kubectl_manifest" "gateway" {
  count = local.shared_gateway ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata   = { name = var.shared_gateway_name, namespace = kubernetes_namespace_v1.gateway[0].metadata[0].name }
    spec = {
      gatewayClassName = "nginx"
      infrastructure = {
        parametersRef = { group = "gateway.nginx.org", kind = "NginxProxy", name = "${var.shared_gateway_name}-proxy" }
      }
      listeners = [
        {
          name          = "http"
          protocol      = "HTTP"
          port          = 80
          hostname      = "*.${var.dns_zone_name}"
          allowedRoutes = local.routes_from_environments
        },
        {
          name     = "https"
          protocol = "HTTPS"
          port     = 443
          hostname = "*.${var.dns_zone_name}"
          tls = {
            mode            = "Terminate"
            certificateRefs = [{ kind = "Secret", name = "${var.shared_gateway_name}-tls" }]
          }
          allowedRoutes = local.routes_from_environments
        },
      ]
    }
  })

  depends_on = [kubectl_manifest.gateway_proxy, kubectl_manifest.gateway_certificate]
}
