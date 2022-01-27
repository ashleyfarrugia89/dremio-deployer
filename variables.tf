variable "region" {
  description = "Azure Region"
  default = "eastus"
}
variable "tags" {
  type = map(string)
  default = {
    Environment = "Field Engineering Test"
    Owner = "ashley.farrugia@dremio.com"
  }
}
variable "environment_name" {
  default = "DREMIO_PROD"
}

variable "admin_username" {
  type        = string
  default     = "aksadmin"
  description = "The admin username set in the linux_profile"
}
variable "default_instance_type" {
  type        = string
  default     = "Standard_D2_v2"
}
variable "exec_instance_type" {
  type        = string
  default     = "Standard_D8_v4"
}
variable "coor_instance_type" {
  type        = string
  default     = "Standard_D8_v4"
}
variable "storage_account_tier"{
  type        = string
  default     = "Standard"
}
variable "subnet_address_space"{
  default = "172.16.0.0/25"
}
variable "ssh_key" {}
variable "aad_group_id" {}
variable "sp_client_id" {}
variable "sp_secret" {}
variable "application_name" {}
variable "tenant_id" {}
variable "subscription_id" {}