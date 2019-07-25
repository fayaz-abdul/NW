variable "delimiter" {
  description = "The delimiter to use when constructing names"
  default     = "_"
}

variable "environment" {
  description = "The environment name"
}

variable "customer" {
  description = "The customer name"
}

variable "project" {
  description = "The project name"
}

variable "ecr_repo_names" {
  description = "ECR repos to be created"
  default = []
}