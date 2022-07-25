variable "resource_group" {}
variable "dns_zone_name" {}
variable "environment_name" {}
variable "region" {
  description = "Azure Region"
  default = "eastus"
}
variable "tags" {}
variable "subnet_name" {}
variable "subnet_address_space" {
  default = ["10.0.0.0/25"]
}
variable "enterprise_app" {
  type = object({
    display_name = string
    object_id    = string
  })
}