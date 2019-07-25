variable "delimiter" {
  description = "The delimiter to use when constructing names"
  default     = "_"
}

variable "environment" {
  description = "The environment name"
  default = "test"
}

variable "customer" {
  description = "mag"
}

variable "project" {
  description = "bi"
}

variable "role" {
  description = "airportforecasting"
}

variable "application" {
  description = "database"
}


variable "charset" {
  description = "The character set for the cluster"
  default     = "utf8"
}


variable "password" {
 description = "The database password"
 default  ="testcrimson"
}
variable "username" {
  description = "The database username"
  default = "airportforecast"
}



variable "db_instance_class" {
  description = "The db instance class to assign to rds instances"
  default     = "db.r3.large"
}

variable "db_instance_count" {
  description = "The number of instances in the aurora cluster"
  default     = 2
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


variable "subnet_ids" {
  type        = "list"
  description = "The list of subnet ids for the aurora instances"
  default     = []
}