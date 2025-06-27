module "eks_bottlerocket" {
  source = "git::https://github.com/JohnMonteir0/terraform-aws-eks.git"

  cluster_name    = local.name
  cluster_version = "1.31"

  create_cloudwatch_log_group              = false
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = local.eks_node_groups

  access_entries = {
    cloud_user = {
      principal_arn = "arn:aws:iam::992382635843:user/cloud_user"
      type          = "STANDARD"

      access_entry = {
        kubernetes_groups = ["system:masters"]
        username          = "cloud_user"
      }
    }
  }
}

