output "aks_cluster_id" {
  value = module.deploy_dremio_aks.aks_cluster_id
}

output "aks_cluster_name" {
  value = module.deploy_dremio_aks.aks_cluster_name
}

output "aks_node_pool_rg"{
  value = module.deploy_dremio_aks.node_resource_group
}

output "client_certificate" {
  value = module.deploy_dremio_aks.client_certificate

  sensitive = true
}

output "client_key" {
  value = module.deploy_dremio_aks.client_key

  sensitive = true
}

output "cluster_ca_certificate" {
  value = module.deploy_dremio_aks.cluster_ca_certificate

  sensitive = true
}

output "cluster_username" {
  value = module.deploy_dremio_aks.cluster_username
}

output "cluster_password" {
  value = module.deploy_dremio_aks.cluster_password
  sensitive = true
}

output "host" {
  value = module.deploy_dremio_aks.host
}

output "dremio_resource_group"{
  value = module.configure_resource_group.dremio_resource_group.name
}

output "dremio_static_ip"{
  value = module.deploy_network.dremio_static_ip
}

output "dremio_static_ip_id"{
  value = module.deploy_network.pip_resource_group
}

output "dremio_storage_account"{
  value = module.deploy_distributed_storage.storage_account
}

output "dremio_container"{
  value = module.deploy_distributed_storage.dremio_container
}
