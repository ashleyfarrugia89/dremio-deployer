terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 0.14.9"
    }
  }
  backend "azurerm" {
    storage_account_name = "dremiotfstorageaccount"
    container_name = "tfstate"
    key = "dremio_aks"
    use_azuread_auth = true
  }
  required_version = ">=0.14.9"
}

provider "azurerm" {
  features {}
}

# import application principal https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal
data "azuread_service_principal" "DREMIO_sp" {
  display_name = var.application_name
}

# create azure resource group
resource "azurerm_resource_group" "DREMIO_rg" {
  name     = "${var.environment_name}_rg"
  location = var.region
  tags     = var.tags
}

# create azure vnet
module "deploy_network" {
  source               = "./modules/network"
  dns_zone_name        = "${var.environment_name}_dns"
  resource_group       = azurerm_resource_group.DREMIO_rg.name
  subnet_name          = "${var.environment_name}_subnet"
  environment_name     = var.environment_name
  subnet_address_space = var.subnet_address_space
  region               = var.region
  tags                 = var.tags
  enterprise_app       = data.azuread_service_principal.DREMIO_sp
  depends_on           = [azurerm_resource_group.DREMIO_rg]
}

# create storage account
module "deploy_distributed_storage" {
  source               = "./modules/storage"
  resource_group       = azurerm_resource_group.DREMIO_rg
  storage_account_tier = var.storage_account_tier
  tags                 = var.tags
  storage_account_name = "dremiostorageaccount"
  aad_group_id         = var.aad_group_id
  enterprise_app       = data.azuread_service_principal.DREMIO_sp
  depends_on           = [azurerm_resource_group.DREMIO_rg]
}

# create AKS cluster and node pools
module "deploy_dremio_aks" {
  source                = "./modules/aks"
  region                = var.region
  resource_group        = azurerm_resource_group.DREMIO_rg.name
  tags                  = var.tags
  cluster_prefix        = var.environment_name
  admin_username        = var.admin_username
  subnet                = module.deploy_network.subnet_id
  ssh_key               = var.ssh_key
  default_instance_name = var.default_instance_type
  coord_instance_type   = "Standard_D8_v4"
  exec_instance_type    = "Standard_D8_v4"
  pip_resource_group    = azurerm_resource_group.DREMIO_rg.id
  sp_client_id          = var.sp_client_id
  sp_secret             = var.sp_secret
  depends_on            = [azurerm_resource_group.DREMIO_rg, module.deploy_network]
}