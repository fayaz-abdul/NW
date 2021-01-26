

variable resource_group_name {
}

variable "location" {
    type = string
}

variable "environment" {
    type = string
}

variable "virtual_network_name" {
    type = string
}

variable "virtual_network_address_space" {
    type = string
}

variable "subnet_postgre_address_prefixes" {
    type = string
}

variable "subnet_functionapp_address_prefixes" {
    type = string
}