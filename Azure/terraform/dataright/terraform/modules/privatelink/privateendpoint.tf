resource "azurerm_private_endpoint" "private_endpoint" {
  name                = "${var.endpoint_name}-${var.environment}-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.postgres_subnet_id

  private_service_connection {
    name                           = "${var.endpoint_name}-${var.environment}-private-service-connection"
    private_connection_resource_id = var.postgresql_server_id
    subresource_names              = [ "postgresqlServer" ]
    is_manual_connection           = false
  }
}


resource "azurerm_app_service_virtual_network_swift_connection" "app_service_virtual_network_swift_connection" {
  app_service_id = var.function_app_id
  subnet_id      = var.functionapp_subnet_id
}