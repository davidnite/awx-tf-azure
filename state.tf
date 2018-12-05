terraform {
  backend "azurerm" {
    storage_account_name = "storageaccountnamegoeshere"
    container_name       = "terraform-state"
    key                  = "awx.terraform.tfstate"
  }
}
