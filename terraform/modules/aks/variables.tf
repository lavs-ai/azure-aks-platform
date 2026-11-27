variable "resource_group_name" {
  description = "Resource group for the cluster."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. Null uses the Azure default."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Initial node count."
  type        = number
}

variable "min_count" {
  description = "Minimum nodes for autoscaling."
  type        = number
}

variable "max_count" {
  description = "Maximum nodes for autoscaling."
  type        = number
}

variable "node_vm_size" {
  description = "VM size for nodes."
  type        = string
}

variable "aks_subnet_id" {
  description = "Resource ID of the subnet for AKS nodes."
  type        = string
}

variable "log_analytics_id" {
  description = "Resource ID of the Log Analytics workspace for Container Insights."
  type        = string
}

variable "tags" {
  description = "Tags applied to the cluster."
  type        = map(string)
  default     = {}
}
