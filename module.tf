module "helm" {
  source = "./helm_release"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  cluster_endpoint                   = module.eks_bottlerocket.cluster_endpoint
  cluster_certificate_authority_data = module.eks_bottlerocket.cluster_certificate_authority_data
  cluster_name                       = module.eks_bottlerocket.cluster_name
  cluster_oidc_issuer_url            = module.eks_bottlerocket.cluster_oidc_issuer_url
  vpc_id                             = module.vpc.vpc_id
  k8s_service_host                   = replace(module.eks_bottlerocket.cluster_endpoint, "https://", "")

  depends_on_modules = [module.eks_bottlerocket]
}