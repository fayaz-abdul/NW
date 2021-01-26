variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}


variable "postgresql_server_name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "start_ip_address" {
  type = string
}
variable "end_ip_address" {
  type = string
}

variable "postgresql_server_sku_name" {
  type = string
}

variable "postgresql_server_version" {
  type = number
}

variable "postgresql_server_storage_mb" {
  type = string
}

variable "postgresql_server_backup_retention_days" {
  type = string
}

variable "postgresql_server_geo_redundant_backup_enabled" {
  type = string
}

variable "postgresql_server_auto_grow_enabled" {
  type = string
}

variable "postgresql_server_public_network_access_enabled" {
  type = string
}

variable "postgresql_server_ssl_enforcement_enabled" {
  type = string
}

variable "postgresql_server_ssl_minimal_tls_version_enforced" {
  type = string
}

variable "postgresql_firewall_name" {
  type = string
}
