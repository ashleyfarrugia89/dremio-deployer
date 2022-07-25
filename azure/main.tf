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

locals {
  project_tags = merge(var.tags, {
    Environment = var.environment_name,
    Owner = "ashley.farrugia@dremio.com"
  })
}

# import application principal https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal
data "azuread_service_principal" "DREMIO_sp" {
  display_name = var.application_name
}

# configure azure resource group
module "configure_resource_group" {
  source = "modules/rg"
  environment_name = var.environment_name
  tags             = local.project_tags
  protected     = var.protected_rg
}

# create azure vnet
module "deploy_network" {
  source               = "modules/network"
  dns_zone_name        = "${var.environment_name}_dns"
  resource_group       = module.configure_resource_group.dremio_resource_group.name
  subnet_name          = "${var.environment_name}_subnet"
  environment_name     = var.environment_name
  subnet_address_space = var.subnet_address_space
  region               = var.region
  tags                 = local.project_tags
  enterprise_app       = data.azuread_service_principal.DREMIO_sp
  depends_on           = [module.configure_resource_group]
}

# create storage account
module "deploy_distributed_storage" {
  source               = "modules/storage"
  resource_group       = module.configure_resource_group.dremio_resource_group
  storage_account_tier = var.storage_account_tier
  tags                 = local.project_tags
  storage_account_name = var.dremio_storage_account
  aad_group_id         = var.aad_group_id
  enterprise_app       = data.azuread_service_principal.DREMIO_sp
  depends_on           = [module.configure_resource_group]
}

# create AKS cluster and node pools
module "deploy_dremio_aks" {
  source                = "modules/aks"
  region                = var.region
  resource_group        = module.configure_resource_group.dremio_resource_group.name
  tags                  = local.project_tags
  cluster_prefix        = var.environment_name
  admin_username        = var.admin_username
  subnet                = module.deploy_network.subnet_id
  ssh_key               = var.ssh_key
  default_instance_name = var.default_instance_type
  coord_instance_type   = var.coor_instance_type
  exec_instance_type    = var.exec_instance_type
  pip_resource_group    = module.configure_resource_group.dremio_resource_group.id
  sp_client_id          = var.sp_client_id
  sp_secret             = var.sp_secret
  depends_on            = [module.configure_resource_group, module.deploy_network]
}