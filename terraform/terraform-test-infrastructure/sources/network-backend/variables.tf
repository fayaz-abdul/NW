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

variable "role" {
  description = "The role name"
}

variable "application" {
  description = "The application name"
}

variable "subnet_cidr_blocks" {
  description = "The cidr ranges for subnets"
  default = []
}

variable "subnet_suffixes" {
  description = "The suffixes to add to subnet names"
  default = [
    "a",
    "b"
  ]
}

variable "tags" {
  description = "The tags to apply to resources"
  default = {}
}

variable "network_acls" {
  description = "The network acls to apply"
  default = []
}

variable "network_acls_port" {
  description = "The network acls with port ranges to apply"
  default = []
}

variable "secgroups" {
  description = "Security groups to be created"
  default = []
}
