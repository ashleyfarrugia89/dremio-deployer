/*
output "access_key" {
  value = azurerm_storage_account.dremiostorageaccount.primary_access_key

  sensitive = true
}*/

output "storage_account" {
  value = azurerm_storage_account.dremiostorageaccount.name
}

output "dremio_container"{
  value = azurerm_storage_container.dremio_reflections.name
}