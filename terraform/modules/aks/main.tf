resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  # Private cluster: the API server is not exposed to the public internet.
  private_cluster_enabled = true

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    min_count           = var.min_count
    max_count           = var.max_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = var.aks_subnet_id
    enable_auto_scaling = true
    # System pool only: user workloads go in a separate pool in production.
    node_labels = {
      "pool" = "system"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_id
  }

  azure_policy_enabled = true
}
