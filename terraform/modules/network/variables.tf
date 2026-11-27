variable "resource_group_name" {
  description = "Resource group for the VNet."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
}

variable "address_space" {
  description = "Address space for the VNet."
  type        = list(string)
}

variable "aks_subnet_prefix" {
  description = "Address prefix for the AKS subnet."
  type        = string
}

variable "app_subnet_prefix" {
  description = "Address prefix for the application subnet."
  type        = string
}

variable "tags" {
  description = "Tags applied to the VNet."
  type        = map(string)
  default     = {}
}
