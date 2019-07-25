 terraform {
  backend "s3" {}
}

data "aws_region" "this" {}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "this" {}

data "aws_kms_secrets" "simplead_pass" {
  secret {
    name    = "simplead_password"
    payload = "AQICAHiuQDAXAy07u5rCbgv3rJFEdFha1KxIiloGop3DZZ0VdAFOxMgW2RWvsBWpea6mYznyAAAAdzB1BgkqhkiG9w0BBwagaDBmAgEAMGEGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMPHrsuYVV3hiAxdazAgEQgDS66fQSmEavOBRDpKs4N+0sg3G9bj3K1mRbi8ZdcULaXeSrg0KaLyTZM6ZI+5C+GtUCHmNN"
  }
}

data "terraform_remote_state" "zone" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "domain/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "vpc/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}

resource "aws_directory_service_directory" "simple_ad" {
  name     = "corp.${var.environment}.${var.project}.${var.customer}.local"    
  password = "${data.aws_kms_secrets.simplead_pass.plaintext["simplead_password"]}"
  size     = "Small"

  vpc_settings {
    vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
    subnet_ids = ["${aws_subnet.subnet.*.id}"]  
  }

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
        join(var.delimiter, compact(list(var.environment, var.customer, var.project, var.role, var.application, "simpleAD"))),
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

module "dns_masq" {
  source = "git@github.com:crimsonmacaw/terraform-aws-dns-masq.git?ref=fa-test"

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"
  role = "test"
  hostedzone_id = "${data.terraform_remote_state.zone.hostedzone_id}"
  route53_records = [
    "a.dns.backend.network.bi.${var.environment}.${var.project}.${var.customer}.local",
    "b.dns.backend.network.bi.${var.environment}.${var.project}.${var.customer}.local"
  ]

  eni_ips = [
    "10.0.1.10",
    "10.0.1.45"
  ]

  ec2_ami_id = "ami-0d3f5f77805e2463a"
  vpc_cidr = "10.0.0.0/23"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  subnet_ids = ["${aws_subnet.subnet.*.id}"]

  dns_ip_addresses = "${aws_directory_service_directory.simple_ad.dns_ip_addresses}"
  listen_address_fqdn = "dns-masq.aws.amazon.com"

  first_ip_of_vpc = "10.0.0.1"
  second_ip_of_vpc = "10.0.0.2"
  cidr_53_ingress = ["172.16.0.0/12"]
  ec2_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDbExOfa5XV6Z71zj7OImYTU/205RlSfR7ukvKc/V6M2YSPZOb5noQ33jer1T+/DwKR1b9ajtp5OeA//pibGLpAsBandOtS9biHgmyUdOORxL31O8fDrZOKz7eY+hMIMqspweU7Gd73BrrXVEB9YlM3dt4ZdNbt7d4tADgPmzg8tAk5zZPcHm1OmyGILIBWadWV9zgWPeopfeb9niJeCjxZq50/IdV0ixkdSNrzqqw3w0WaSLrHuSRs6m+HdGdz8xp2urga7lHPbU7Q3wbuZFpElphYXukzPiyXuzb4KYyaQsyNn/4x7d39AiM7ycNWXUvTJZzX9YsNmMBBIIV0Ibp4usx+I3KBDJIsCwaouil5ZC/i07XzFc0GidxJbx1WKgAJdDTOrutYXBWLllqMQS1tvlPXOb6Ya8RqHnpgbFRUOSKzfhkbALlyeviBRisR6lS1ErXFhf2KB+1zDPOlZLxuVZoGJjBHsoH4VmOzZ5dPgaFKgf6zoqhhXr3ITb0qv8oVuatQY7naH2fjYExuwCYnk1mKWWHmU5OqxAcL7dqae9z5o/dAnOI92VAi+tDlH9eiI9Vi84VN3zcs8NF8Y1H1cUrFA3lrNat7DDJICllYeLOCYy3OGRyyi1tH7HZZ24wu3LhX4QhIjV5pZjMGIBlD6SH2oFHu/rKWxNRjTcxf6Q== fayaz.abdul@crimsonmacaw.com"

}


module "squid" {
  source = "git@github.com:crimsonmacaw/terraform-aws-squid.git"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"  
  elb_subnet_ids = ["${aws_subnet.subnet.*.id}"]
  is_internal= "true"
  instance_subnet_ids = ["${aws_subnet.subnet.*.id}"]
  vpc_endpoint_s3_id = "${data.terraform_remote_state.vpc.vpc_endpoint_s3_id}" 
  ec2_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDbExOfa5XV6Z71zj7OImYTU/205RlSfR7ukvKc/V6M2YSPZOb5noQ33jer1T+/DwKR1b9ajtp5OeA//pibGLpAsBandOtS9biHgmyUdOORxL31O8fDrZOKz7eY+hMIMqspweU7Gd73BrrXVEB9YlM3dt4ZdNbt7d4tADgPmzg8tAk5zZPcHm1OmyGILIBWadWV9zgWPeopfeb9niJeCjxZq50/IdV0ixkdSNrzqqw3w0WaSLrHuSRs6m+HdGdz8xp2urga7lHPbU7Q3wbuZFpElphYXukzPiyXuzb4KYyaQsyNn/4x7d39AiM7ycNWXUvTJZzX9YsNmMBBIIV0Ibp4usx+I3KBDJIsCwaouil5ZC/i07XzFc0GidxJbx1WKgAJdDTOrutYXBWLllqMQS1tvlPXOb6Ya8RqHnpgbFRUOSKzfhkbALlyeviBRisR6lS1ErXFhf2KB+1zDPOlZLxuVZoGJjBHsoH4VmOzZ5dPgaFKgf6zoqhhXr3ITb0qv8oVuatQY7naH2fjYExuwCYnk1mKWWHmU5OqxAcL7dqae9z5o/dAnOI92VAi+tDlH9eiI9Vi84VN3zcs8NF8Y1H1cUrFA3lrNat7DDJICllYeLOCYy3OGRyyi1tH7HZZ24wu3LhX4QhIjV5pZjMGIBlD6SH2oFHu/rKWxNRjTcxf6Q== fayaz.abdul@crimsonmacaw.com"    

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"

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
        join(var.delimiter, compact(list(var.environment, var.customer, var.project, var.role, var.application, "squid"))),
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
