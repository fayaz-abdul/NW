variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_name" {
  type = string
}

variable "access_key" {
  type = string
}

# variable "connection_string" {
#     type = string
# }

variable "application_insights_instrumentation_key" {

}


variable "environment" {
  type = string
}



variable "app_function_name" {
  type = string
}

# variable "deployment_name" {
#     type = string
# }

variable "app_service_plan_name" {
  type = string
}

variable "app_service_plan_kind" {
  type = string
}

variable "app_service_plan_reserved" {
  type = string
}