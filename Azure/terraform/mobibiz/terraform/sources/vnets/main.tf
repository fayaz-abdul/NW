provider "azurerm" {
  version = "~>1.11"
}

terraform {
  backend "azurerm" {}
}

resource "azurerm_virtual_network" "network" {
  name                = join("-", [var.resource_group_name, "vnet"])
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = {
    customer = var.customer
    project = var.project
    environment = var.environment
  }
}

resource "azurerm_subnet" "aks_subnet" {
  name           = join("-", [var.resource_group_name, "aks-subnet"])
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefix = var.aks_subnet_address
  resource_group_name = var.resource_group_name
}


resource "azurerm_subnet" "postgres_subnet" {
  name           = join("-", [var.resource_group_name, "postgres-subnet"])
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefix = var.postgres_subnet_address
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "elastic_subnet" {
  name           = join("-", [var.resource_group_name, "elastic-subnet"])
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefix = var.elastic_subnet_address
  resource_group_name = var.resource_group_name
}
