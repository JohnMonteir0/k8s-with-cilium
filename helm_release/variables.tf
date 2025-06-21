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