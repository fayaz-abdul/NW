
#COMMON VARIABLES
company_name = "dataright"
environment  = "sbx"

location = "East US"

##DATABASE VARIABLES
start_ip_address                                   = "0.0.0.0"
end_ip_address                                     = "255.255.255.255"
postgresql_server_sku_name                         = "GP_Gen5_4"
postgresql_server_version                          = 11
postgresql_server_storage_mb                       = 10240
postgresql_server_backup_retention_days            = 7
postgresql_server_geo_redundant_backup_enabled     = "true"
postgresql_server_auto_grow_enabled                = "true"
postgresql_server_public_network_access_enabled    = "true"
postgresql_server_ssl_enforcement_enabled          = "true"
postgresql_server_ssl_minimal_tls_version_enforced = "TLS1_2"
postgresql_firewall_name                           = "dataright"

#FUNCTIONAPP VARIABLES
#while creating the resources you need to set the below values 

# app_service_plan_kind = "linux"
# app_service_plan_reserved = "true"

#while updating the resource you need to set the below values 

#PLEASE COMMENTOUT THE VALUES ACCORDINGLY

app_service_plan_kind = "elastic"
app_service_plan_reserved = "true"



#############-VNET VARS-##########

virtual_network_address_space = "10.0.0.0/16"
subnet_postgre_address_prefixes = "10.0.1.0/24"
subnet_functionapp_address_prefixes = "10.0.2.0/24"
