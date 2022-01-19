terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 0.14.9"
    }
  }
  required_version = ">=0.14.9"
}

# create user MI
resource "azurerm_user_assigned_identity" "aksidentity" {
  name                = "${var.cluster_prefix}_MI"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}
