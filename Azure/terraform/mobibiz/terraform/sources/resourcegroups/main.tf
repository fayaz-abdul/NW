provider "azurerm" {
  version = "~>1.11"
}

terraform {
  backend "azurerm" {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
