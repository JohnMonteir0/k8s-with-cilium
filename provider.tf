terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-backend-terraformbackends3bucket-ofisdte40rf6"
    key            = "backend"
    region         = "us-east-1"
    dynamodb_table = "terraform-backend-TerraformBackendDynamoDBTable-1K28VR621CGUA"
  }
}

provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks_bottlerocket.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_bottlerocket.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_bottlerocket.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_bottlerocket.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_bottlerocket.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_bottlerocket.cluster_name]
    }
  }
}


data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
