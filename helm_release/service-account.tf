### Load Ballancer Controller ###
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_load_balancer_controller.arn
    }
  }
}

### EBS CSI Controller ###
resource "kubernetes_service_account" "eks_ebs_csi_controller" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_ebs_csi_controller.arn
    }
  }
}

### Cluster Autoscaler ###
resource "kubernetes_service_account" "eks_cluster_autoscaler" {
  metadata {
    name      = "eks-cluster-autoscaler"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_cluster_autoscaler.arn
    }
  }
}