terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 0.14.9"
    }

    azuread = {
      version = ">= 0.6"
    }
  }
  required_version = ">=0.14.9"
}

# create log analytics
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "dremio-law"
  resource_group_name = var.resource_group
  location            = var.region
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "workspace" {
  solution_name         = "Containers"
  workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
  workspace_name        = azurerm_log_analytics_workspace.workspace.name
  location              = var.region
  resource_group_name   = var.resource_group

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }
}

resource "azurerm_kubernetes_cluster" "Dremio_AKS_Cluster" {
  location            = var.region
  name                = "${var.cluster_prefix}_AKS_Cluster"
  resource_group_name = var.resource_group
  tags                = var.tags
  dns_prefix = "dremio-cluster"
  service_principal {
    client_id     = var.sp_client_id
    client_secret = var.sp_secret
  }
  default_node_pool {
    name       = "default"
    vm_size    = var.default_instance_name
    vnet_subnet_id = var.subnet
    node_count = 3
    tags       = var.tags
    node_labels = {
      vmsize = "small"
    }
  }
  role_based_access_control {
    enabled = true
  }
  dynamic "linux_profile"{
    for_each = var.ssh_key == "" ? [] : [1]
    content {
      admin_username = var.admin_username
      ssh_key {
        key_data = file(var.ssh_key)
      }
    }
  }
  addon_profile {
    http_application_routing {
      enabled = false
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "AKS_Cluster_Coord" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.Dremio_AKS_Cluster.id
  name                  = "coordpool"
  vm_size               = var.coord_instance_type
  tags                  = var.tags
  mode                  = "User"
  node_count            = 1 # assuming you only need one coordinator
  vnet_subnet_id = var.subnet
  node_labels = {
    vmsize = "large"
    type   = "coordinator"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "AKS_Cluster_Exec" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.Dremio_AKS_Cluster.id
  name                  = "executorpool"
  vm_size               = var.exec_instance_type
  tags                  = var.tags
  mode                  = "User"
  enable_auto_scaling   = "true"
  min_count             = 1
  max_count             = 5
  vnet_subnet_id = var.subnet
  node_labels = {
    vmsize = "large"
    type   = "executor"
  }
}