variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "k8s_service_host" {
  type = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type = string
}

variable "cluster_endpoint" {
  description = "Endpoint for Kubernetes API server"
  type = string
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster security group will be provisioned"
  type        = string
  default     = null
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "The OIDC issuer URL from the EKS cluster"
}

variable "depends_on_modules" {
  description = "Modules to wait for before applying helm releases"
  type        = list(any)
  default     = []
}

variable "install_cilium" {
  description = "Whether to install Cilium and all dependent Helm charts"
  type        = bool
  default     = false
}