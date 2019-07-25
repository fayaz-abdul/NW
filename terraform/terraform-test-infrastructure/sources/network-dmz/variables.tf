variable "current_transition_standard_ia_days" {
  description = "The number of days to transition the current version to STANDARD_IA storage class"
  default = 30
}


variable "eni_ips" {
  description = "The ips of the network interface"
  default     =  ["10.0.1.71", "10.0.1.103"]
}


variable "enable_nat_gateways" {
  description = "Should be true if NAT Gateways should be created"
  default     = true
}

variable "nat_gateway_subnets" {
  description = "The public subnet index"
  default     = [0, 1]
}
variable "current_transition_glacier_days" {
  description = "The number of days to transition the current version to GLACIER storage class"
  default = 90
}

variable "noncurrent_transition_glacier_days" {
  description = "The number of days to transition the non current version to GLACIER storage class"
  default = 30
}

variable "availability_zones" {
  description = "The availablility zones to build in"
  default     = ["a","b"]
}

variable "public_subnets" {
  description = "The public subnet data"

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
  default     = "10.0.1.64/26"
}

variable "delimiter" {
  description = "The delimiter used when generating names"
  default     = "_"
}

variable "public_label" {
  description = "The label to assign to public subnets"
  default     = "public"
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

