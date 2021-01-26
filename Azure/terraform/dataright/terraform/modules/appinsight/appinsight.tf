resource "azurerm_application_insights" "application_insights" {
  name                = "${var.application_insights_name}-${var.environment}-application-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  tags = {
    environment = var.environment
    project     = "dataright"
    owner       = "terraform"
    region      = var.location
    tier        = "app"
    costcentre  = ""
  }
}


output "application_insights_instrumentation_key" {
  value = azurerm_application_insights.application_insights.instrumentation_key
}