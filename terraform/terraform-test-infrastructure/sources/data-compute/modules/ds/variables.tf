variable "environment" {
  description = "The name of the environment"
  default     = "dev"
}

variable "customer" {
  description = "The name of the customer"
  default     = ""
}

variable "project" {
  description = "The name of the project"
  default     = ""
}

variable "role" {
  description = "The name of the role"
  default     = ""
}

variable "application" {
  description = "The name of the application"
  default     = ""
}

variable "tags" {
  description = "A map of additional tags to apply"
  default     = {}
}

variable "description" {
  description = "Description for the module"
}

variable "rstudio_container_name" {
  description = "Name for rstudio container"
  default = "rstudio_container"
}

variable "rstudio_image_id" {
  description = "Image id to run in rstudio ecs instance"
}
