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

data "terraform_remote_state" "zone" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "domain/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}

module "dc-logstash" {
  source = "./modules/logstash"

  description            = "Logstash instance for data compute"  

  vpc_id                 = "${data.terraform_remote_state.vpc.vpc_id}"
  instance_subnet_ids    = "${aws_subnet.subnet.*.id}"
  instance_type          = "m5.xlarge"
  ec2_public_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDbExOfa5XV6Z71zj7OImYTU/205RlSfR7ukvKc/V6M2YSPZOb5noQ33jer1T+/DwKR1b9ajtp5OeA//pibGLpAsBandOtS9biHgmyUdOORxL31O8fDrZOKz7eY+hMIMqspweU7Gd73BrrXVEB9YlM3dt4ZdNbt7d4tADgPmzg8tAk5zZPcHm1OmyGILIBWadWV9zgWPeopfeb9niJeCjxZq50/IdV0ixkdSNrzqqw3w0WaSLrHuSRs6m+HdGdz8xp2urga7lHPbU7Q3wbuZFpElphYXukzPiyXuzb4KYyaQsyNn/4x7d39AiM7ycNWXUvTJZzX9YsNmMBBIIV0Ibp4usx+I3KBDJIsCwaouil5ZC/i07XzFc0GidxJbx1WKgAJdDTOrutYXBWLllqMQS1tvlPXOb6Ya8RqHnpgbFRUOSKzfhkbALlyeviBRisR6lS1ErXFhf2KB+1zDPOlZLxuVZoGJjBHsoH4VmOzZ5dPgaFKgf6zoqhhXr3ITb0qv8oVuatQY7naH2fjYExuwCYnk1mKWWHmU5OqxAcL7dqae9z5o/dAnOI92VAi+tDlH9eiI9Vi84VN3zcs8NF8Y1H1cUrFA3lrNat7DDJICllYeLOCYy3OGRyyi1tH7HZZ24wu3LhX4QhIjV5pZjMGIBlD6SH2oFHu/rKWxNRjTcxf6Q== fayaz.abdul@crimsonmacaw.com"

  environment            = "${var.environment}"
  customer               = "${var.customer}"
  project                = "${var.project}"
  role                   = "data"
  application            = "compute"

  ecs_cluster_name       = "${var.environment}_${var.customer}_${var.project}_${var.role}_${var.application}_logstash_ecs"
  iam_policies           = [
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",    
  ]
}

# @Todo Add ingress rule for 80 in NACL/Routes and test ec2 working. Add missing LogGroup resource.
# Also replace hardcoded values with vars in container definitons.
module "dc-rstudio" {
  source = "./modules/rstudio"

  description            = "Logstash instance for data compute"  

  vpc_id                 = "${data.terraform_remote_state.vpc.vpc_id}"
  instance_subnet_ids    = "${aws_subnet.subnet.*.id}"
  instance_type          = "m4.large"
  ec2_public_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDbExOfa5XV6Z71zj7OImYTU/205RlSfR7ukvKc/V6M2YSPZOb5noQ33jer1T+/DwKR1b9ajtp5OeA//pibGLpAsBandOtS9biHgmyUdOORxL31O8fDrZOKz7eY+hMIMqspweU7Gd73BrrXVEB9YlM3dt4ZdNbt7d4tADgPmzg8tAk5zZPcHm1OmyGILIBWadWV9zgWPeopfeb9niJeCjxZq50/IdV0ixkdSNrzqqw3w0WaSLrHuSRs6m+HdGdz8xp2urga7lHPbU7Q3wbuZFpElphYXukzPiyXuzb4KYyaQsyNn/4x7d39AiM7ycNWXUvTJZzX9YsNmMBBIIV0Ibp4usx+I3KBDJIsCwaouil5ZC/i07XzFc0GidxJbx1WKgAJdDTOrutYXBWLllqMQS1tvlPXOb6Ya8RqHnpgbFRUOSKzfhkbALlyeviBRisR6lS1ErXFhf2KB+1zDPOlZLxuVZoGJjBHsoH4VmOzZ5dPgaFKgf6zoqhhXr3ITb0qv8oVuatQY7naH2fjYExuwCYnk1mKWWHmU5OqxAcL7dqae9z5o/dAnOI92VAi+tDlH9eiI9Vi84VN3zcs8NF8Y1H1cUrFA3lrNat7DDJICllYeLOCYy3OGRyyi1tH7HZZ24wu3LhX4QhIjV5pZjMGIBlD6SH2oFHu/rKWxNRjTcxf6Q== fayaz.abdul@crimsonmacaw.com"

  environment            = "${var.environment}"
  customer               = "${var.customer}"
  project                = "${var.project}"
  role                   = "data"
  application            = "compute"

  ecs_cluster_name       = "${var.environment}_${var.customer}_${var.project}_${var.role}_${var.application}_rstudio_ecs"
  rstudio_container_name = "${var.environment}_${var.customer}_${var.project}_${var.role}_${var.application}_rstudio"
  rstudio_image_id       = "387984460553.dkr.ecr.eu-west-1.amazonaws.com/test_crimson_bi_data_analytics_ecr/r_studio:latest"
  iam_policies           = [
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",    
  ]

  hosted_zone_id         = "${data.terraform_remote_state.zone.hostedzone_id}"
}

module "kms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description            = "Encryption key for data compute"
  delimiter              = "_"

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "data"
  application     = "compute"
  confidentiality = "private"
}

module "s3" {
  source = "git@github.com:crimsonmacaw/terraform-aws-s3.git"

  enforce_encryption = ["aws:kms"]
  enable_versioning  = true
  delimiter          = "_"

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"
  role        = "data"
  application = "compute"
}

# @Todo Missing RDS instance with dr197q6tql3o7x4 id. Present in CloudFormation, missing in RDS.

# @Todo Missing Matillion EC2 instance i-086079b16c38e8ee2. Present in CloudFormation, missing in EC2 instance.

