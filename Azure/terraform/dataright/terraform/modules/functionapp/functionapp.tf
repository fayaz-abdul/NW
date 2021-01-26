
resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.app_service_plan_name}-${var.environment}-app-service-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = var.app_service_plan_kind
  reserved = var.app_service_plan_reserved
  sku {
    tier = "elastic"
    size = "EP1"
  }
     tags = {
    environment = var.environment
    project = "dataright"
    owner = "terraform"
    region = var.location
    tier = "app"
    costcentre = ""
   }
}

resource "azurerm_function_app" "function_app" {
  name                       = "${var.app_function_name}-${var.environment}-function-app"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  storage_account_name       = var.storage_name
  storage_account_access_key = var.access_key
  version                    = "~3"
  app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.application_insights_instrumentation_key,
    "FUNCTIONS_EXTENSION_VERSION"           = "~3",
    "FUNCTIONS_WORKER_RUNTIME"              = "node",
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = "InstrumentationKey=${var.application_insights_instrumentation_key};IngestionEndpoint=https://eastus-1.in.applicationinsights.azure.com/",
    "WEBSITE_DNS_SERVER"                    = "168.63.129.16",
    "WEBSITE_VNET_ROUTE_ALL"                = "1"
  }
  os_type = "linux"
  identity {
    type = "SystemAssigned"
  }
  tags = {
    environment = var.environment
    project     = "dataright"
    owner       = "terraform"
    region      = var.location
    tier        = "app"
    costcentre  = ""
  }
}

# resource "azurerm_app_service" "app_service" {
#   name                = "${var.app_function_name}-${var.environment}-function-app-service"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
# }

# output "app_service_id" {
#   value = azurerm_app_service.app_service.id
# }
# output "app_service_plan_id" {
#   value = azurerm_app_service_plan.app_service_plan.id
# }

output  "function_app_id" {
  value =  azurerm_function_app.function_app.id
} 

output "function_app_principal_id" {
  value = azurerm_function_app.function_app.identity[0].principal_id
}

output "function_app_tenant_id" {
  value = azurerm_function_app.function_app.identity[0].tenant_id
}
