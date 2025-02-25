# variables.tf
variable "location" {
  default = "eastus"
}

#Enter your resource group name
variable "resource_group_name" {
  default = "Enter Your RG Here"
}

#Enter your tenant ID
variable "tenant_id" {
  default = "Enter your tenant ID Here"
}

#Enter your key vault ID
variable "key_vault_id" {
  default = "Enter your Keyvault ID Here"
}

#Enter your user object ID (this is the object ID of the user who will have access to the key vault)
variable "user_object_id" {
  default = "Enter your User Object ID Here"
}
