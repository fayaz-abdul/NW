variable "vpc_id" {
  description = "The vpc id for the openvpn instance"
}

variable "instance_subnet_ids" {
  type        = "list"
  description = "The list of subnet ids for the ecs instances"
}

variable "instance_type" {
  description = "The instance type to use for ec2 instances"
  default     = "t2.micro"
}

variable "ec2_public_key" {
  description = "The ec2 public key"
}

variable "iam_policies" {
  description = "The list of iam policies to apply to the EC2 instances"

  default = [
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
  ]
}

variable "ecs_cluster_name" {
  description = "The ecs cluster name"
  default = "ecs-cluster"
}

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