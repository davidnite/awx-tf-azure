variable "subscription_id" {
  default = "azure-sub"
}
variable "client_id" {
  default = "azure-client"
}
variable "client_secret" {
  default = "azure-secret"
}
variable "tenant_id" {
  default = "azure-tenant"
}
variable "location" {
  default = "southcentralus"
}

variable "admin_username" {
  default = "awxadmin"
}
variable "public_ssh_key_data" {
  default = "ssh-data-here"
}

variable "address_space" {
  default = "10.0.0.0/24"
}

variable "awx_pass" {}
variable "gitlab_user" {
  default = "user@email.com"
}
variable "gitlab_pass" {
  default = "P@ssw0Rd!"
}
variable "aws_password" {
  default = "P@ssw0Rd!"
}
variable "dns_zone" {}
