terraform {
  backend "s3" {}
}

data "aws_region" "this" {}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "this" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "vpc/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}

data "aws_kms_secret" "rds" {
  secret {
    name    = "master_password"
    payload = "AQICAHg6feGRNGxAerEfOMAZysMy0VqkW4ZZ3Oqf2BhoxYVSJwHWzHGrLZbobs/wTfD90ILLAAAAaTBnBgkqhkiG9w0BBwagWjBYAgEAMFMGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMQ6YuskxCqPoCNo+YAgEQgCaINsOXv2U33HO8B3NFjHwm7SiUcUYBlYrk9c5IGVnm77Hb16uLLQ=="

    context {
      foo = "bar"
    }
  }
}

module "data_store_sqlserver_ds" {
  source = "git@github.com:crimsonmacaw/terraform-aws-rds-sqlserver.git"
  
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  subnet_ids  = ["${aws_subnet.subnet.*.id}"]
  kms_key_arn          = "${module.data_store_ds_kms.kms_key_arn}"
  username             = "root"
  password             = "${data.aws_kms_secret.rds.master_password}"
  vpc_endpoint_s3_id   = "${data.terraform_remote_state.vpc.vpc_endpoint_s3_id}" 
  engine_subtype       = "se"
  major_engine_version = "14.0"
  minor_engine_version = "3035.2.v1"
  db_instance_class = "db.m4.large"
  allocated_storage = 50
 
  skip_final_snapshot = true



  environment = "${terraform.workspace}"
  customer    = "mag"
  project     = "bi"
  role        = "data"
  application = "store"
}



module "data_store_ds_kms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description            = "Encryption key for data store rds"
  include_region_in_name = true
  services               = ["*"] 

  environment     = "${terraform.workspace}"
  customer        = "mag"
  project         = "bi"
  role            = "data"
  application     = "store_rds"
  confidentiality = "private"
}


module "datastore_redshiftkms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description            = "Create the kms keys for the Redshift Data store"
  delimiter              = "_"
  create_iam_policies    = "false"
  override_policy_json   = "${data.aws_iam_policy_document.redshift_kms.json}"
  include_region_in_name = "${var.datastore_include_region_in_name}"

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "${var.role}"
  application     = "${join(var.delimiter, compact(list(var.application, "redshift-kms")))}"
  confidentiality = "private"
}
  
data "terraform_remote_state" "zone" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "domain/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}

data "terraform_remote_state" "dns_ip_addresses" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "network-backend/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}

resource "null_resource" "private_subnets" {
  count = "${length(var.private_subnets["indexes"])}"

  triggers {
    newbits           = "${element(var.private_subnets["newbits"], count.index)}"
    index             = "${element(var.private_subnets["indexes"], count.index)}"
    label             = "${element(var.private_subnets["labels"], count.index)}"
    availability_zone = "${element(var.private_subnets["availability_zones"], count.index)}"
  }
}

resource "aws_subnet" "private" {
  count  = "${length(var.private_subnets["indexes"])}"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  cidr_block = "${cidrsubnet(
    var.cidr,
    element(null_resource.private_subnets.*.triggers.newbits, count.index),
    element(null_resource.private_subnets.*.triggers.index, count.index)
  )}"

  availability_zone = "${join("", list(data.aws_region.this.name, element(null_resource.private_subnets.*.triggers.availability_zone, count.index)))}"

  tags = "${merge(
    var.tags,
    zipmap(
      compact(list(
        "Name",
        var.environment != "" ? "environment" : "",
        var.customer != "" ? "customer" : "",
        var.project != "" ? "project" : "",
        var.role != "" ? "role" : "",
        var.application != "" ? "application" : "",
        "tf:meta"
      )),
      compact(list(
        join(var.delimiter, compact(
          list(
            var.environment,
            var.customer,
            var.project,
            var.role,
            var.application,
            element(null_resource.private_subnets.*.triggers.label, count.index),
            var.private_label,
            element(null_resource.private_subnets.*.triggers.availability_zone, count.index),
            "subnet"
          ))
        ),
        var.environment,
        var.customer,
        var.project,
        var.role,
        var.application,
        "terraform"
      ))
    )
  )}"
}

module "store_source_s3copybucket" {
  source = "git@github.com:crimsonmacaw/terraform-aws-s3.git"

  create_iam_policies = "${var.s3_module_create_iam_policies}"
  enforce_encryption  = ["aws:kms"]
  enable_versioning   = true
  delimiter           = "_"

  include_region_in_name = false

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"
  role        = "${var.role}"
  application = "${var.application}"
  suffix      = "sourcebucket"
}

module "store_firehouse_kinesiskms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description            = "Create the kms keys for kinesis Data store"
  delimiter              = "_"
  create_iam_policies    = "false"
  override_policy_json   = "${data.aws_iam_policy_document.kms_firehouse.json}"
  include_region_in_name = "${var.store_include_region_in_name}"

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "${var.role}"
  application     = "${join(var.delimiter, compact(list(var.application, "kinesis-kms")))}"
  confidentiality = "private"
}

module "store_redshiftkms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description            = "Create the kms keys for the Redshift Data store"
  delimiter              = "_"
  create_iam_policies    = "false"
  override_policy_json   = "${data.aws_iam_policy_document.redshift_kms.json}"
  include_region_in_name = "${var.datastore_include_region_in_name}"
  include_region_in_name = "${var.store_include_region_in_name}"

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "${var.role}"
  application     = "${join(var.delimiter, compact(list(var.application, "redshift-kms")))}"
  confidentiality = "private"
}

module "store_crmkms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description            = "Create the kms keys for the CRM Data store"
  delimiter              = "_"
  create_iam_policies    = "false"
  override_policy_json   = "${data.aws_iam_policy_document.crm_kms.json}"
  include_region_in_name = "${var.store_include_region_in_name}"

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "${var.role}"
  application     = "${join(var.delimiter, compact(list(var.application, "redshift")))}"
  confidentiality = "private"
}

module "datastore_source_s3copybucket" {
  source = "git@github.com:crimsonmacaw/terraform-aws-s3.git"

  create_iam_policies = "${var.s3_module_create_iam_policies}"
  enforce_encryption  = ["aws:kms"]
  enable_versioning   = true
  delimiter           = "_"
=======
  application     = "${join(var.delimiter, compact(list(var.application, "crm-kms")))}"
  confidentiality = "private"
}

module "store_firehose_s3" {
  source = "git@github.com:crimsonmacaw/terraform-aws-firehose-s3.git?ref=fa-test"

  delimiter       = "_"
  s3_bucket_arn   = "${module.store_source_s3copybucket.s3_bucket_arn}"
  s3_prefix       = "${var.store_s3_prefix}"
  buffer_size     = "${var.store_buffer_size}"
  buffer_interval = "${var.store_buffer_interval}"
  kms_key_arn     = "${module.store_firehouse_kinesiskms.kms_key_arn}"
  iam_policies    = "${aws_iam_policy.kinesispolicy.arn}"

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"
  role        = "${var.role}"
  application = "${var.application}"
}

module "store_module_redshift" {
  source = "git@github.com:crimsonmacaw/tf-redshift-infrastructure.git//modules/redshift?ref=test"

  #TO DO EIP attachment

  dbpass               = "${var.store_redshift_password}"
  subnet_ids           = ["${aws_subnet.private.*.id}"]
  publicly_accessible  = "${var.store_redshift_publicly_accessible}"
  eip_accessible       = "${var.store_redshift_eip_accessible}"
  node_type            = "${var.store_redshift_cluster_node_type}"
  number_nodes         = "${var.store_redshift_cluster_number_of_nodes}"
  cluster_version      = "${var.store_redshift_cluster_version}"
  redshift_secgroup_id = "${aws_security_group.redshift.id}"
  cluster_iam_roles    = ["${aws_iam_role.redshiftrole.arn}"]
  kms_key_id           = "${module.store_redshiftkms.kms_key_arn}"
  enabled_logging      = "${var.store_redshift_enabled_logging}"
  environment          = "${var.environment}"
  customer             = "${var.customer}"
  project              = "${var.project}"
  role                 = "${var.role}"
  application          = "${var.application}"
}

#data "aws_redshift_cluster" "test_cluster" {
#  cluster_identifier = "${var.environment}-${var.customer}-${var.project}-${var.role}-${var.application}-redshift"
#}

data "aws_kms_secret" "ad_joiner_password" {
  secret {
    name    = "ad"
    payload = "${local.ad_joiner_password}"
  }
}

module "sftp_source_s3copybucket" {
  source = "git@github.com:crimsonmacaw/terraform-aws-s3.git"

  enforce_encryption = ["aws:kms"]
  enable_versioning  = true
  delimiter          = "_"
>>>>>>> test

  include_region_in_name = false

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"
  role        = "${var.role}"
  application = "${var.application}"
<<<<<<< HEAD
  suffix      = "sourcecopybucket"
}
#############


module "datastore_bodyscannerkms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"
  
  description            = "Create the kms keys for the kinesis"
  delimiter              = "_"
  create_iam_policies    = "false"
  override_policy_json   = "${data.aws_iam_policy_document.redshift_kms.json}"
  include_region_in_name = "${var.datastore_include_region_in_name}"
=======
  suffix      = "sourcebucket-sftp"
}

module "store_sftp_kms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description            = "Create the kms keys for the sftp Data store"
  delimiter              = "_"
  override_policy_json   = "${data.aws_iam_policy_document.sftp_kms.json}"
  include_region_in_name = "${var.store_include_region_in_name}"
>>>>>>> test

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "${var.role}"
<<<<<<< HEAD
  application     = "${join(var.delimiter, compact(list(var.application, "bodyscanner")))}"
  confidentiality = "private"
}

=======
  application     = "${join(var.delimiter, compact(list(var.application, "sftp")))}"
  confidentiality = "private"
}

module "sftp" {
  source = "git@github.com:crimsonmacaw/terraform-aws-sftp.git"

  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  sftp_source_cidrs = [
    "191.1.0.0/16",
    "191.2.0.0/16",
    "10.250.200.0/24",
    "10.250.201.0/24",
    "10.250.251.0/24",
    "10.250.210.0/24",
    "10.6.1.0/24",
    "10.150.1.0/24",
    "10.150.8.0/24",
  ]

  #Need to check on passing roles from KMS and S3 modules
  sftp_iam_policies = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ]

  ec2_public_key     = "${local.sftp_ec2_public_key}"
  hostedzone_id      = "${data.terraform_remote_state.zone.hostedzone_id}"
  ec2_instance_type  = "${local.sftp_ec2_instance_type}"
  ad_joiner_password = "${data.aws_kms_secret.ad_joiner_password.ad}"
  ad_joiner_user     = "${local.ad_joiner_user}"
  ad_access_filter   = "${local.ad_access_filter}"
  s3_target_bucket   = "${module.sftp_source_s3copybucket.s3_bucket_id}"
  s3_target_key      = "${local.target_s3_key}"
  s3_kms_key_id      = "${module.store_sftp_kms.kms_key_id}"
  landing_directory  = "${local.sftp_landing_directory}"
  subnet_ids         = "${aws_subnet.private.*.id}"
  delimiter          = "-"
  start_time         = "${local.sftp_start_time}"
  end_time           = "${local.sftp_end_time}"
  deployment_mode    = "${local.sftp_deployment_mode}"
  sftp_dns_name      = "sftp.${terraform.workspace}.test.bi.crimsonmacaw.local"
  dns_cidrs          = ["${var.dns_ip_addresses[0]}/32", "${var.dns_ip_addresses[1]}/32"]
  ebs_volume_size    = "${local.sftp_ebs_volume_size}"

  initial_ec2_autoscaling_size = "${local.sftp_initial_size}"

  ssh_host_rsa_key         = "${local.ssh_host_rsa_key}"
  ssh_host_rsa_key_pub     = "${local.ssh_host_rsa_key_pub}"
  ssh_host_ecdsa_key       = "${local.ssh_host_ecdsa_key}"
  ssh_host_ecdsa_key_pub   = "${local.ssh_host_ecdsa_key_pub}"
  ssh_host_ed25519_key     = "${local.ssh_host_ed25519_key}"
  ssh_host_ed25519_key_pub = "${local.ssh_host_ed25519_key_pub}"

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"
  role        = "${var.role}"
  application = "${var.application}"
}
>>>>>>> test
