terraform {
  backend "s3" {}
}

data "aws_region" "this" {}

data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*.h-amazon-ecs-optimized"]
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "logstash-infrastructure")))}"
  max_size                  = 8
  min_size                  = 2
  launch_configuration      = "${aws_launch_configuration.this.name}"
  health_check_type         = "EC2"
  health_check_grace_period = 300
  desired_capacity          = 2  
  vpc_zone_identifier       = ["${var.instance_subnet_ids}"]

  tags = ["${list(
    map("key", "Name", "value", join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "logstash", "infrastructure"))), "propagate_at_launch", true),
    map("key", "tf:meta", "value", "terraform", "propagate_at_launch", true)
  )}"]
}

resource "aws_launch_configuration" "this" {
  name_prefix          = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "logstash", "infrastructure")))}-"
  image_id             = "${data.aws_ami.this.id}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.instance.id}"]
  user_data            = "${data.template_file.user_data.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.this.id}"
  key_name             = "${aws_key_pair.this.key_name}"

  // Only for testing.
  // associate_public_ip_address  = true

  # aws_launch_configuration can not be modified.
  # Therefore we use create_before_destroy so that a new modified aws_launch_configuration can be created
  # before the old one get's destroyed. That's why we use name_prefix instead of name.
  lifecycle {
    create_before_destroy = true
  }
}


data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.tpl")}"

  vars {
    region                = "${data.aws_region.this.name}"
    environment           = "${var.environment}"
    customer              = "${var.customer}"
    project               = "${var.project}"
    role                  = "${var.role}"
    application           = "${var.application}"
 
    category              = "logstash"
    component             = "data-compute"
    LogstashMountTargetA  = "${aws_efs_mount_target.mount_a.id}"
    LogstashMountTargetB  = "${aws_efs_mount_target.mount_b.id}"    
    LogstashEcsCluster    = "${aws_ecs_cluster.cluster.name}"             
  }
}

resource "aws_cloudwatch_log_group" "logstash" {
  name              = "/${join("/", compact(list("aws", "ec2", "logstash", "var", "log", "logstash", "access.log")))}"
  retention_in_days = 30
}
