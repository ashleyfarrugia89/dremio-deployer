output "id" {
  value = azurerm_virtual_network.DREMIO_vnet.id
}

output "subnet_id" {
  value = element(azurerm_virtual_network.DREMIO_vnet.subnet.*.id, 0)
}

output "pip_resource_group" {
  value = azurerm_public_ip.DREMIO_PIP.id
}

output "dremio_static_ip" {
  value = azurerm_public_ip.DREMIO_PIP.ip_address
}