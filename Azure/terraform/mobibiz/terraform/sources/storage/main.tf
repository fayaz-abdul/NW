provider "azurerm" {
  version = "~>1.37"
}

terraform {
  backend "azurerm" {}
}

resource "azurerm_storage_account" "storage" {
  name                = join("", [replace(var.resource_group_name, "-", ""), "data"])
  location            = var.location
  resource_group_name = var.resource_group_name
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "GRS"
  provisioner "local-exec" {
    command = "az storage blob service-properties update --account-name ${azurerm_storage_account.storage.name} --static-website  --index-document index.html --404-document 404.html"
  }
  
  tags = {
    customer = var.customer
    project = var.project
    environment = var.environment
  }
}

resource "azurerm_storage_container" "cert" {
  name                  = "cert"
  container_access_type = "container"
  storage_account_name  = azurerm_storage_account.storage.name
}

resource "azurerm_storage_container" "media" {
  name                  = "media"
  container_access_type = "container"
  storage_account_name  = azurerm_storage_account.storage.name
}

resource "azurerm_storage_container" "static" {
  name                  = "static"
  container_access_type = "container"
  storage_account_name  = azurerm_storage_account.storage.name
}
