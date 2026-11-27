variable "resource_group_name" {
  description = "Name of the resource group for all platform resources."
  type        = string
  default     = "rg-aks-platform-demo"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "australiaeast"
}

variable "environment" {
  description = "Environment label applied as a tag (e.g. demo, sit, uat, prod)."
  type        = string
  default     = "demo"
}

variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
  default     = "vnet-aks-platform"
}

variable "vnet_address_space" {
  description = "Address space for the VNet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "Address prefix for the AKS subnet."
  type        = string
  default     = "10.0.0.0/22"
}

variable "app_subnet_prefix" {
  description = "Address prefix for the application subnet."
  type        = string
  default     = "10.0.4.0/22"
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "aks-platform-demo"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster."
  type        = string
  default     = "aksplatform"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS. Leave null to use the Azure default."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Initial node count for the system node pool."
  type        = number
  default     = 1
}

variable "min_count" {
  description = "Minimum nodes for cluster autoscaling."
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum nodes for cluster autoscaling."
  type        = number
  default     = 3
}

variable "node_vm_size" {
  description = "VM size for AKS nodes."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "acr_name" {
  description = "Globally unique name for the Azure Container Registry (lowercase, alphanumeric only)."
  type        = string
  default     = "acraksplatformdemo"
}

variable "key_vault_name" {
  description = "Globally unique name for Key Vault (lowercase, alphanumeric and hyphens)."
  type        = string
  default     = "kv-aks-platform-demo"
}

variable "log_analytics_name" {
  description = "Name of the Log Analytics workspace."
  type        = string
  default     = "log-aks-platform-demo"
}

variable "tags" {
  description = "Extra tags merged into every resource."
  type        = map(string)
  default     = {}
}
