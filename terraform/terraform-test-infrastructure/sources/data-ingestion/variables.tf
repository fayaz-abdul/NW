variable "current_transition_standard_ia_days" {
  description = "The number of days to transition the current version to STANDARD_IA storage class"
  default = 30
}

variable "current_transition_glacier_days" {
  description = "The number of days to transition the current version to GLACIER storage class"
  default = 90
}

variable "noncurrent_transition_glacier_days" {
  description = "The number of days to transition the non current version to GLACIER storage class"
  default = 30
}

variable "private_subnets" {
  description = "The private subnet data"

  default = {
    labels             = ["", ""]
    newbits            = [1, 1]
    indexes            = [0, 1]
    availability_zones = ["a", "b"]
  }
}

variable "role" {
  description = "The role name"
  default = ""
}

variable "application" {
  description = "The application name"
  default = ""
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.192/26"
}

variable "delimiter" {
  description = "The delimiter used when generating names"
  default     = "_"
}

variable "private_label" {
  description = "The label to assign to private subnets"
  default     = "private"
}

variable "default_tags" {
  description = "default tags for all components"
  type        = "map"
  default     = {}
}

variable "tags" {
  description = "A map of additional tags to apply"
  default     = {}
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

variable "enable_nat_gateways" {
  description = "Should be true if NAT Gateways should be created"
  default     = true
}

variable "nat_gateway_subnets" {
  description = "The public subnet index"
  default     = [0, 1]
}
