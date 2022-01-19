output "client_id" {
  value = azurerm_user_assigned_identity.aksidentity.id
}

output "principal_id" {
  value = azurerm_user_assigned_identity.aksidentity.principal_id
}

output "tenant_id" {
  value = azurerm_user_assigned_identity.aksidentity.tenant_id
}