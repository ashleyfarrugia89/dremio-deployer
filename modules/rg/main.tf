terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 0.14.9"
    }
  }
  required_version = ">=0.14.9"
}


locals {
  protected_tag = {
    "Protected" : "True"
  }
}

resource "azurerm_resource_group" "DREMIO_rg" {
  # added create resource only when a resource group name is not provided
  name     = var.azure_resource_group != "" ? var.azure_resource_group : "${var.environment_name}_rg"
  location = var.region
  tags     = var.protected? merge(var.tags, local.protected_tag): var.tags
}