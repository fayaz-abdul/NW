variable "delimiter" {
  description = "The delimiter to use when constructing names"
  default     = "_"
}

variable "environment" {
  description = "The environment name"
  default = "test"
}

variable "datastore_include_region_in_name" {
  default = true
}

variable "customer" {
  description = "mag"
}

variable "project" {
  description = "bi"
}

variable "role" {
  description = "data"
}

variable "application" {
  description = "store"
}


variable "charset" {
  description = "The character set for the cluster"
  default     = "utf8"
}


variable "password" {
 description = "The database password"
 default  =""
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

variable "datastore_s3_copy_destination" {
  default = "undefined"
}

variable "datastore_s3_copy_destination_prefix" {
  default = "undefined"
}

variable "datastore_s3_copy_source_prefix" {
  default = "undefined"
}

variable "s3_module_create_iam_policies" {
  description = "Should be true if the iam policies should be created"
  default     = false
}
/*
variable "skip_final_snapshot" {
  description = "When the database is terminated should a final snapshot be skipped"
  default     = true
}
*/
variable "current_transition_standard_ia_days" {
  description = "The number of days to transition the current version to STANDARD_IA storage class"
  default     = 30
}

variable "current_transition_glacier_days" {
  description = "The number of days to transition the current version to GLACIER storage class"
  default     = 90
}

variable "noncurrent_transition_glacier_days" {
  description = "The number of days to transition the non current version to GLACIER storage class"
  default     = 30
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
  default     = ""
}

variable "application" {
  description = "The application name"
  default     = ""
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.128/26"
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

variable "KinesisStream_ExternalAccountId" {
  default = 387984460553
}

variable "s3_module_create_iam_policies" {
  default = false
}

variable "store_include_region_in_name" {
  default = true
}

variable "store_lambda_code_versionid" {
  default = "undefined"
}

variable "store_lambdafunctioncodebucket" {
  default = "undefined"
}

variable "store_lambdafunctioncodekey" {
  default = "undefined"
}

variable "store_s3_copy_destination" {
  default = "undefined"
}

variable "store_s3_copy_destination_prefix" {
  default = "undefined"
}

variable "store_s3_copy_source_prefix" {
  default = "undefined"
}

variable "store_redshift_password" {
  description = "The Redshift Cluster password"
  default     = "AQICAHiuQDAXAy07u5rCbgv3rJFEdFha1KxIiloGop3DZZ0VdAFOxMgW2RWvsBWpea6mYznyAAAAdzB1BgkqhkiG9w0BBwagaDBmAgEAMGEGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMPHrsuYVV3hiAxdazAgEQgDS66fQSmEavOBRDpKs4N+0sg3G9bj3K1mRbi8ZdcULaXeSrg0KaLyTZM6ZI+5C+GtUCHmNN"
}

variable "store_redshift_publicly_accessible" {
  default = true
}

variable "store_redshift_eip_accessible" {
  default = true
}

variable "store_redshift_enabled_logging" {
  default = false
}

variable "store_redshift_cluster_node_type" {
  default = "dc1.large"

  # Valid Values: dc1.large | dc1.8xlarge | dc2.large | dc2.8xlarge | ds2.xlarge | ds2.8xlarge.
  # http://docs.aws.amazon.com/cli/latest/reference/redshift/create-cluster.html
}

variable "store_redshift_cluster_version" {
  description = "Version of Redshift engine cluster"
  default     = "1.0"

  # Constraints: Only version 1.0 is currently available.
  # http://docs.aws.amazon.com/cli/latest/reference/redshift/create-cluster.html
}

variable "store_redshift_cluster_number_of_nodes" {
  default = 2
}

variable "store_redshift_lambdafunctioncodebucket" {
  default = "undefined"
}

variable "store_redshift_lambdafunctioncodekey" {
  default = "undefined"
}

variable "store_redshift_lambdaversionid" {
  default = "undefined"
}

variable "store_s3_prefix" {
  default = "undefined"
}

variable "store_buffer_size" {
  default = 10
}

variable "store_buffer_interval" {
  default = 400
}

variable "store_iam_policies" {
  default = true
}

variable "dns_ip_addresses" {
  description = "The DNS server IP address"

  default = [
    "10.0.1.128",
    "10.0.1.129",
  ]
}
