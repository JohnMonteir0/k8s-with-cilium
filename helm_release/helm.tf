resource "helm_release" "cilium" {
  count            = var.install_cilium ? 1 : 0
  name             = "cilium"
  repository       = "https://helm.cilium.io/"
  chart            = "cilium"
  version          = "1.17.4"
  namespace        = "kube-system"
  create_namespace = false

  values = [templatefile("${path.module}/templates/cilium-values.yaml.tmpl", {
    k8s_service_host = var.k8s_service_host
  })]
}

resource "helm_release" "aws_load_balancer_controller" {
  count      = var.install_cilium && var.enable_eks_addons ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  values = [
    templatefile("${path.module}/templates/aws-load-balancer-controller-values.yaml.tmpl", {
      cluster_name = var.cluster_name
      region       = data.aws_region.current.name
      vpc_id       = var.vpc_id
      role_arn     = aws_iam_role.eks_load_balancer_controller.arn
    })
  ]

  depends_on = [
    helm_release.cilium,
    aws_iam_role_policy_attachment.attach_load_balancer_policy
  ]
}

resource "helm_release" "ingress_nginx" {
  count            = var.install_cilium && var.enable_eks_addons ? 1 : 0
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.2"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [
  templatefile("${path.module}/templates/ingress-nginx-values.yaml.tmpl", {
    annotations = local.annotations
  })
]

  timeout     = 900              # Increase time
  wait        = true             # Wait until resources are ready
  atomic      = true             # Roll back on failure
  recreate_pods = true

  depends_on = [
    helm_release.cilium,
    helm_release.aws_load_balancer_controller
  ]
}

resource "helm_release" "ebs_csi_driver" {
  count      = var.install_cilium && var.enable_eks_addons ? 1 : 0
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.30.0"

  values = [
    templatefile("${path.module}/templates/ebs-csi-driver-values.yaml.tmpl", {
      role_arn = aws_iam_role.eks_ebs_csi_controller.arn
    })
  ]

  depends_on = [
    helm_release.cilium,
    aws_iam_role_policy_attachment.attach_ebs_csi_policy
  ]
}

resource "helm_release" "cluster_autoscaler" {
  count      = var.install_cilium && var.enable_eks_addons ? 1 : 0
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.29.0"

  values = [
    templatefile("${path.module}/templates/cluster-autoscaler-values.yaml.tmpl", {
      cluster_name = var.cluster_name
      region       = var.aws_region
      role_arn     = aws_iam_role.eks_cluster_autoscaler.arn
    })
  ]

  depends_on = [
    helm_release.cilium,
    aws_iam_role_policy_attachment.attach_cluster_autoscaler_policy
  ]
}

resource "helm_release" "coredns" {
  count      = var.install_cilium && var.enable_eks_addons ? 1 : 0
  name       = "coredns"
  chart      = "coredns"
  repository = "https://coredns.github.io/helm"
  namespace  = "kube-system"
  version    = "1.27.1"

  values = [
    templatefile("${path.module}/templates/coredns-values.yaml.tmpl", {})
  ]

  depends_on = [
    helm_release.cilium
  ]
}
