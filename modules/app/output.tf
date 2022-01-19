output "app_id" {
  value = azuread_application.dremio-app.application_id
}
/*
output "app_secret" {
  value = azuread_application_password.dremio-secret.value
  sensitive = true
}*/
