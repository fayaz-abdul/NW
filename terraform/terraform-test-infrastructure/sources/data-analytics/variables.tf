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
  default     = []
}

variable "subnet_suffixes" {
  description = "The suffixes to add to subnet names"

  default = [
    "a",
    "b",
  ]
}

variable "tags" {
  description = "The tags to apply to resources"
  default     = {}
}

variable "network_acls" {
  description = "The network acls to apply"
  default     = []
}

variable "network_acls_port" {
  description = "The network acls with port ranges to apply"
  default     = []
}

variable "secgroups" {
  description = "Security groups to be created"
  default     = []
}

variable "s3_module_create_iam_policies" {
  description = "Should be true if the iam policies should be created"
  default     = false
}

variable "analytics_include_region_in_name" {
  default = true
}

variable "analytics_lambda_code_versionid" {
  default = "undefined"
}

variable "analytics_lambdafunctioncodebucket" {
  default = "undefined"
}

variable "analytics_lambdafunctioncodekey" {
  default = "undefined"
}

variable "analytics_s3_copy_destination" {
  default = "undefined"
}

variable "analytics_s3_copy_destination_prefix" {
  default = "undefined"
}

variable "analytics_s3_copy_source_prefix" {
  default = "undefined"
}

variable "analytics_redshift_password" {
  description = "The Redshift Cluster password"
  default     = "AQICAHiuQDAXAy07u5rCbgv3rJFEdFha1KxIiloGop3DZZ0VdAFOxMgW2RWvsBWpea6mYznyAAAAdzB1BgkqhkiG9w0BBwagaDBmAgEAMGEGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMPHrsuYVV3hiAxdazAgEQgDS66fQSmEavOBRDpKs4N+0sg3G9bj3K1mRbi8ZdcULaXeSrg0KaLyTZM6ZI+5C+GtUCHmNN"
}

variable "analytics_redshift_publicly_accessible" {
  default = true
}

variable "analytics_redshift_eip_accessible" {
  default = true
}

variable "analytics_redshift_enabled_logging" {
  default = false
}

variable "analytics_redshift_cluster_node_type" {
  default = "dc1.large"

  # Valid Values: dc1.large | dc1.8xlarge | dc2.large | dc2.8xlarge | ds2.xlarge | ds2.8xlarge.
  # http://docs.aws.amazon.com/cli/latest/reference/redshift/create-cluster.html
}

variable "analytics_redshift_cluster_version" {
  description = "Version of Redshift engine cluster"
  default     = "1.0"

  # Constraints: Only version 1.0 is currently available.
  # http://docs.aws.amazon.com/cli/latest/reference/redshift/create-cluster.html
}

variable "analytics_redshift_cluster_number_of_nodes" {
  default = 2
}

variable "analytics_redshift_lambdafunctioncodebucket" {
  default = "undefined"
}

variable "analytics_redshift_lambdafunctioncodekey" {
  default = "undefined"
}

variable "analytics_redshift_lambdaversionid" {
  default = "undefined"
}
