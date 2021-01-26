resource "azurerm_storage_account" "storage_account" {
  name                     = "${var.storage_account_name}${var.environment}storage"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  static_website {
    index_document = "index.html"
  }
  tags = {
    environment = var.environment
    project     = "dataright"
    owner       = "terraform"
    region      = var.location
    tier        = "storage"
    costcentre  = ""
  }
}

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "storage_account_primary_access_key" {
  value = azurerm_storage_account.storage_account.primary_access_key
}

output "storage_account_primary_web_endpoint" {
  value = azurerm_storage_account.storage_account.primary_web_endpoint
}