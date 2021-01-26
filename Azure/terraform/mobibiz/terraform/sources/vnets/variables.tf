variable "resource_group_name" {
  description = "The resource group name"
}

variable "location" {
  description = "The location"
}

variable "customer" {
  description = "The customer name"
}

variable "project" {
  description = "Thr project name"
}

variable "environment" {
  description = "The environment name"
}

variable "vnet_address_space" {
  description = "The environment name"
  type    = list(string)
}

variable "aks_subnet_address" {
  description = "The environment name"
}

variable "postgres_subnet_address" {
  description = "The environment name"
}

variable "elastic_subnet_address" {
  description = "The environment name"
}
