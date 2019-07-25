terraform {
  backend "s3" {}
}

data "aws_region" "this" {}

data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*.a-amazon-ecs-optimized"]
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio-infrastructure")))}"
  max_size                  = 2
  min_size                  = 1
  launch_configuration      = "${aws_launch_configuration.this.name}"
  health_check_type         = "EC2"
  health_check_grace_period = 0
  desired_capacity          = 1
  vpc_zone_identifier       = ["${var.instance_subnet_ids}"]
  service_linked_role_arn   = "${aws_iam_service_linked_role.asg_service_role.arn}"

  tags = ["${list(
    map("key", "Name", "value", join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "infrastructure"))), "propagate_at_launch", true),
    map("key", "tf:meta", "value", "terraform", "propagate_at_launch", true)
  )}"]
}

resource "aws_launch_configuration" "this" {
  name_prefix          = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "infrastructure")))}-"
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
 
    category              = "rstudio"
    component             = "data-compute"
    RstudioMountTargetA  = "${aws_efs_mount_target.mount_a.id}"
    RstudioMountTargetB  = "${aws_efs_mount_target.mount_b.id}"    
    RstudioEcsCluster    = "${aws_ecs_cluster.cluster.name}"             
  }
}

resource "aws_cloudwatch_log_group" "rstudio" {
  name              = "/${join("/", compact(list("aws", "ec2", "logstash", "var", "log", "rstudio", "access.log")))}"
  retention_in_days = 30
}
