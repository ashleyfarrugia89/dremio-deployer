variable "resource_group" {}
variable "region" {}
variable "tags" {
  type = map(string)
}
variable "cluster_prefix" {}
variable "default_instance_name" {}
variable "ssh_key" {}
variable "admin_username" {}
variable "coord_instance_type" {}
variable "exec_instance_type" {}
#variable "aad_group_name" {}
variable "subnet" {}
variable "pip_resource_group" {}
variable "sp_client_id" {}
variable "sp_secret" {}
variable "log_analytics"{
  default = false
}