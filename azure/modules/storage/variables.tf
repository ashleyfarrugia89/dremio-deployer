variable "storage_account_name" {
  default     = "dremiostorageaccount"
}
variable "storage_account_tier"{
  type        = string
  default     = "Standard"
}
variable "resource_group" {
  type        = any
}
variable "tags" {
  type        = map(string)
}
variable "account_replication_type" {
  default     = "LRS"
}
variable "account_kind" {
  default     = "StorageV2"
}
variable "access_tier" {
  default     = "Hot"
}
variable "aad_group_id" {}
variable "enterprise_app" {
  type = object({
    display_name = string
    object_id    = string
  })
}