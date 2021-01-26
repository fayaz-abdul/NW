resource "azurerm_postgresql_server" "postgresql_server" {
  name                = "${var.postgresql_server_name}-${var.environment}-postgresql-server"
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login          = var.username
  administrator_login_password = var.password

  sku_name   = var.postgresql_server_sku_name
  version    = var.postgresql_server_version
  storage_mb = var.postgresql_server_storage_mb

  backup_retention_days        = var.postgresql_server_backup_retention_days
  geo_redundant_backup_enabled = var.postgresql_server_geo_redundant_backup_enabled
  auto_grow_enabled            = var.postgresql_server_auto_grow_enabled

  public_network_access_enabled    = var.postgresql_server_public_network_access_enabled
  ssl_enforcement_enabled          = var.postgresql_server_ssl_enforcement_enabled
  ssl_minimal_tls_version_enforced = var.postgresql_server_ssl_minimal_tls_version_enforced
  tags = {
    environment = var.environment
    project     = "dataright"
    owner       = "terraform"
    region      = var.location
    tier        = "db"
    costcentre  = ""
  }
}

resource "azurerm_postgresql_firewall_rule" "postgresql_firewall_rule" {
  name                = "${var.postgresql_firewall_name}-${var.environment}-postgresql-firewall-rule"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.postgresql_server.name
  start_ip_address    = var.start_ip_address
  end_ip_address      = var.end_ip_address
}

output "postgresql_server_id" {
  value = azurerm_postgresql_server.postgresql_server.id
}