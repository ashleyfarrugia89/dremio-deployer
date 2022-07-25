terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 0.14.9"
    }
  }
  required_version = ">=0.14.9"
}

# create storage account
resource azurerm_storage_account "dremiostorageaccount" {
  name = var.storage_account_name
  resource_group_name = var.resource_group.name
  location = var.resource_group.location
  account_tier = var.storage_account_tier
  account_replication_type = var.account_replication_type
  tags = var.tags
  account_kind = var.account_kind
  access_tier = var.access_tier
}

# create container
resource azurerm_storage_container "dremio_reflections" {
  name = "dremiocache"
  storage_account_name = azurerm_storage_account.dremiostorageaccount.name
  container_access_type = "private"
}

# assign role to enterprise app
resource "azurerm_role_assignment" "enterprise_app_storage_ro" {
  principal_id = var.enterprise_app.object_id
  scope        = azurerm_storage_account.dremiostorageaccount.id
  role_definition_name = "Storage Blob Data Contributor"
}