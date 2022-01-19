output "aks_cluster_id" {
  value = "${azurerm_kubernetes_cluster.Dremio_AKS_Cluster.id}"
}

output "aks_cluster_name" {
  value = "${azurerm_kubernetes_cluster.Dremio_AKS_Cluster.name}"
}

output "routing_zone_name"{
  value = "${azurerm_kubernetes_cluster.Dremio_AKS_Cluster.addon_profile[0].http_application_routing[0].http_application_routing_zone_name}"
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.Dremio_AKS_Cluster.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.Dremio_AKS_Cluster.kube_config_raw

  sensitive = true
}

output "client_key" {
    value = azurerm_kubernetes_cluster.Dremio_AKS_Cluster.kube_config.0.client_key
}

output "cluster_ca_certificate" {
    value = azurerm_kubernetes_cluster.Dremio_AKS_Cluster.kube_config.0.cluster_ca_certificate
}

output "cluster_username" {
    value = azurerm_kubernetes_cluster.Dremio_AKS_Cluster.kube_config.0.username
}

output "cluster_password" {
    value = azurerm_kubernetes_cluster.Dremio_AKS_Cluster.kube_config.0.password
}

output "host" {
    value = azurerm_kubernetes_cluster.Dremio_AKS_Cluster.kube_config.0.host
}

output "node_resource_group"{
    value = azurerm_kubernetes_cluster.Dremio_AKS_Cluster.node_resource_group
}