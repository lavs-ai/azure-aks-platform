terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Remote state is deliberately NOT configured here: this is a portfolio
  # project and the backend (storage account + container) is account-
  # specific. In a real team, add an azurerm backend block pointing at
  # the shared state storage account, with state locking enabled.
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

locals {
  tags = merge(var.tags, {
    project     = "aks-platform-demo"
    environment = var.environment
    managed-by  = "terraform"
  })
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = var.vnet_name
  address_space       = var.vnet_address_space
  aks_subnet_prefix   = var.aks_subnet_prefix
  app_subnet_prefix   = var.app_subnet_prefix
  tags                = local.tags
}

module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  cluster_name        = var.cluster_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  node_count          = var.node_count
  min_count           = var.min_count
  max_count           = var.max_count
  node_vm_size        = var.node_vm_size
  aks_subnet_id       = module.network.aks_subnet_id
  log_analytics_id    = azurerm_log_analytics_workspace.main.id
  tags                = local.tags
}

resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false # AKS pulls via its managed identity, not admin creds
  tags                = local.tags
}

# Least privilege: the AKS kubelet identity may pull images, nothing else.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_key_vault" "main" {
  name                       = var.key_vault_name
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # demo only; enable in production
  tags                       = local.tags

  # The deploying identity gets secret-management rights so the pipeline
  # can seed demo secrets. Application workloads get narrower access
  # via a separate role assignment (see below).
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete"]
  }
}

# Least privilege: the AKS cluster identity may read secrets, not manage them.
resource "azurerm_role_assignment" "aks_key_vault_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks.cluster_identity_object_id
}

resource "azurerm_monitor_metric_alert" "node_cpu_high" {
  name                = "aks-node-cpu-high"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [module.aks.cluster_id]
  description         = "Alert when average node CPU is high for 5 minutes."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name       = "node_cpu_usage_percentage"
    aggregation       = "Average"
    operator          = "GreaterThan"
    threshold         = 80
  }
}

resource "azurerm_monitor_metric_alert" "pod_restarts" {
  name                = "aks-pod-restarts-high"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [module.aks.cluster_id]
  description         = "Alert when pods are restarting repeatedly."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name       = "kube_pod_container_status_restarts_total"
    aggregation       = "Total"
    operator          = "GreaterThan"
    threshold         = 10
  }
}
