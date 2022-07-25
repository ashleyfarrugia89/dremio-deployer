variable "cluster_prefix" {
  default = "dev.ajf-cluster"
}
variable "region" {}
variable "vpc_id" {}
variable "subnet_id" {}
variable "security_group_id" {}
variable "engine_type" {
  default = "standard"
}
variable "engine_size" {
  default = "small"
}
variable "instance_profile" {
  type = any
}
variable "efs_path" {
  default = "/var/dremio_efs"
}
variable "dremio_userid" {
  default = 2000
}
variable "dremio_groupid" {
  default = 2000
}
variable "dremio_log_path" {
  default = "/var/log/dremio"
}
variable "zk_quorum" {
  default = "zookeeper"
}
variable "tags" {
  type = any
}