terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 0.14.9"
    }
  }
  required_version = ">=0.14.9"
}

resource "azurerm_virtual_network" "DREMIO_vnet" {
  address_space       = [var.subnet_address_space]
  location            = var.region
  name                = "${var.environment_name}_vnet"
  resource_group_name = var.resource_group
  tags                 = var.tags
  subnet {
    name           = var.subnet_name
    address_prefix = var.subnet_address_space
  }
}

resource "azurerm_public_ip" "DREMIO_PIP" {
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  location            = var.region
  name                = "${var.environment_name}_PIP"
  sku                 = "Standard"
}

# grant enterprise application access to PIP
resource "azurerm_role_assignment" "DREMIO_PIP_RA" {
  principal_id = var.enterprise_app.object_id
  scope        = azurerm_public_ip.DREMIO_PIP.id
  role_definition_name = "Network Contributor"
}