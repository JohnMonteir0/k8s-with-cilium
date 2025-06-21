variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "enable_node_groups" {
  description = "Controls whether EKS managed node groups should be created"
  type        = bool
  default     = true
}
