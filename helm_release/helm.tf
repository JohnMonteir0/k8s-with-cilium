resource "helm_release" "cilium" {
  name             = "cilium"
  repository       = "https://helm.cilium.io/"
  chart            = "cilium"
  version          = "1.17.4"
  namespace        = "kube-system"
  create_namespace = false

  values = [templatefile("${path.module}/cilium-values.yaml.tmpl", {
    k8s_service_host = var.k8s_service_host
  })]
}
