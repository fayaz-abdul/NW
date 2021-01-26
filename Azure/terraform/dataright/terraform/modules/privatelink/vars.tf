

variable resource_group_name {
}

variable "location" {
    type = string
}

variable "environment" {
    type = string
}

variable "endpoint_name" {
    type = string
}

variable "postgres_subnet_id" {
    type = string
}

variable "postgresql_server_id" {
    type = string
}


variable "function_app_id" {
    type = string
}

variable "functionapp_subnet_id" {
    type = string
}