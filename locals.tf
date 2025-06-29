locals {
  name   = "cilium-cluster"
  region = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Cluster    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

locals {
  eks_node_groups = var.enable_node_groups ? {
    cilium-node-group = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["t3.medium"]

      private_networking = true

      min_size     = 2
      max_size     = 5
      desired_size = 2

      bootstrap_extra_args = <<-EOT
        [settings.host-containers.admin]
        enabled = false

        [settings.host-containers.control]
        enabled = true

        [settings.kernel]
        lockdown = "integrity"
      EOT
    }
  } : {}
}


### CoreDNS Install
locals {
  cluster_addons = var.install_coredns ? {
    coredns = {}
  } : {}
}