# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
terraform {
  backend "azurerm" {
    container_name       = "sbx"
    key                  = ".terraform.tfstate"
    resource_group_name  = "rg-dataright-terraform"
    storage_account_name = "stdatarightterraform"
  }
}
