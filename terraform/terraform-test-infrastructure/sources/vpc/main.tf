terraform {
  backend "s3" {}
}

module "vpc" {
  source = "git@github.com:crimsonmacaw/terraform-aws-vpc.git"

  cidr                    = "${var.cidr_base}/${var.cidr_bits}"
  private_subnets         = {
    "indexes" = []
  }

  public_subnets          = {
    "indexes" = []
  }
  enable_nat_gateways     = false
  enable_s3_endpoint      = true
  enable_internet_gateway = false
  enable_dns_support      = true
  enable_dns_hostnames    = true

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"
}
