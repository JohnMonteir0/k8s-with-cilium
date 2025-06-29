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

variable "enable_eks_addons" {
  description = "Controls whether EKS add-ons should be installed"
  type        = bool
  default     = false
}

variable "install_cilium" {
  description = "Controls whether Cilium should be installed"
  type        = bool
  default     = false
}

variable "install_coredns" {
  description = "Controls whether CoreDNS should be installed"
  type        = bool
  default     = false
}
