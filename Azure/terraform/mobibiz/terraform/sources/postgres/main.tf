provider "azurerm" {
  version = "~>1.11"
}

terraform {
  backend "azurerm" {}
}

resource "azurerm_postgresql_server" "postgres" {
  name                = join("-", [var.resource_group_name, "postgres-server"])
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = "GP_Gen5_2"
    capacity = 2
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 104448
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
    auto_grow             = "Enabled"
  }
  administrator_login          = "emtrailsadmin"
  administrator_login_password = var.postgres_admin_password
  version                      = "11"
  ssl_enforcement              = "Disabled"

  tags = {
    customer = var.customer
    project = var.project
    environment = var.environment
  }
}

resource "azurerm_postgresql_virtual_network_rule" "postgres-rule" {
  name                                 = join("-", [var.resource_group_name, "postgres-vnet-rule"])
  resource_group_name                  = var.resource_group_name
  server_name                          = azurerm_postgresql_server.postgres.name
  subnet_id                            = var.postgres_subnet_id
  ignore_missing_vnet_service_endpoint = true
}
