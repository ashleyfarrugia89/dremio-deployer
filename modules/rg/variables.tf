variable "region" {
  description = "Azure Region"
  default = "eastus"
}
variable "tags" {}
variable "azure_resource_group" {
  default = ""
}
variable "environment_name" {}
variable "protected" {}