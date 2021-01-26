provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=2.20.0"
  features {}
}

module "resourcegroup" {
  source = "../modules/resourcegroup"
  resource_group_name = var.company_name
  location = var.location
  environment = var.environment
}


module "storageaccount" {
  source = "../modules/storage"
  storage_account_name = var.company_name
  resource_group_name = module.resourcegroup.resource_group_name
  location = var.location
  environment = var.environment
}

module "appinsight" {
  source = "../modules/appinsight"
  application_insights_name = var.company_name
  resource_group_name = module.resourcegroup.resource_group_name
  location = var.location
  environment = var.environment
}
 

module "functionapp" {
  source = "../modules/functionapp"
  app_service_plan_name = var.company_name
  app_function_name = var.company_name
  resource_group_name = module.resourcegroup.resource_group_name
  location = var.location
  access_key = module.storageaccount.storage_account_primary_access_key
  storage_name = module.storageaccount.storage_account_name
  application_insights_instrumentation_key = module.appinsight.application_insights_instrumentation_key
  environment = var.environment
  app_service_plan_kind = var.app_service_plan_kind
  app_service_plan_reserved = var.app_service_plan_reserved
  # deployment_name = module.storageaccount.deployment_name
  }

module "keyvault" {
  source = "../modules/keyvault"
  resource_group_name = module.resourcegroup.resource_group_name
  location = var.location
  function_app_tenant_id = module.functionapp.function_app_tenant_id
  function_app_principal_id = module.functionapp.function_app_principal_id
  environment = var.environment
  keyvault-name = var.company_name
  }

module "azurecdn" {
  source = "../modules/azurecdn"
  resource_group_name = module.resourcegroup.resource_group_name
  location = var.location
  storage_name = module.storageaccount.storage_account_name
  primary_web_endpoint = module.storageaccount.storage_account_primary_web_endpoint
  environment = var.environment
  cdn_profile_name = var.company_name
  cdn_profile_sku = var.cdn_profile_sku
  }


module "vnet" {
  source = "../modules/vnet"
  resource_group_name = module.resourcegroup.resource_group_name
  location = var.location
  environment = var.environment
  virtual_network_name = var.company_name
  virtual_network_address_space = var.virtual_network_address_space
  subnet_postgre_address_prefixes = var.subnet_postgre_address_prefixes
  subnet_functionapp_address_prefixes = var.subnet_functionapp_address_prefixes
  }

module "database" {
  source = "../modules/database"
  resource_group_name = module.resourcegroup.resource_group_name
  location = var.location
  postgresql_server_name = var.company_name
  environment = var.environment
  username = var.username
  password = var.password
  start_ip_address = var.start_ip_address
  end_ip_address = var.end_ip_address
  postgresql_server_sku_name = var.postgresql_server_sku_name
  postgresql_server_version = var.postgresql_server_version
  postgresql_server_storage_mb = var.postgresql_server_storage_mb
  postgresql_server_backup_retention_days =var.postgresql_server_backup_retention_days
  postgresql_server_geo_redundant_backup_enabled =var.postgresql_server_geo_redundant_backup_enabled
  postgresql_server_auto_grow_enabled =var.postgresql_server_auto_grow_enabled
  postgresql_server_public_network_access_enabled =var.postgresql_server_public_network_access_enabled
  postgresql_server_ssl_enforcement_enabled =var.postgresql_server_ssl_enforcement_enabled
  postgresql_server_ssl_minimal_tls_version_enforced =var.postgresql_server_ssl_minimal_tls_version_enforced
  postgresql_firewall_name = var.company_name

  }


# module "privateendpoint" {
#   source = "../modules/privatelink"
#   resource_group_name = module.resourcegroup.resource_group_name
#   location = var.location
#   environment = var.environment
#   endpoint_name = var.company_name
#   #postgre_subnet = module.vnet.subnet_postgres
#   # postgre_subnet = module.vnet.subnet_id_postgres[0].id
#   postgresql_server_id = module.database.postgresql_server_id
#   # app_service_id = module.functionapp.app_service_id
#   postgres_subnet_id = module.vnet.postgres_subnet_id
#   functionapp_subnet_id = module.vnet.functionapp_subnet_id
#   function_app_id = module.functionapp.function_app_id
#   }

# output "subnet" {
#   value = module.vnet.subnet_id_postgres[0].id
# }

# output "newsubnet" {
#   value = module.vnet.subnet_id_postgres
# }