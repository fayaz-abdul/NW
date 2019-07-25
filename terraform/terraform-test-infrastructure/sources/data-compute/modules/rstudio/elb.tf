
resource "aws_lb_target_group" "rstudio_ecs_tg" {
  name     = "${var.environment}-${var.role}-${var.application}-rstudio-ecs-tg"
  port     = 8787
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_listener" "rstudio_ecs_listener" {
  load_balancer_arn = "${aws_lb.rstudio_ecs_lb.arn}"
  port              = "8787"
  protocol          = "HTTP"  

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.rstudio_ecs_tg.arn}"
  }
}

resource "aws_lb" "rstudio_ecs_lb" {
  name               = "${join("-", compact(list(var.environment, var.role, var.application, "rstudio", "elb")))}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${var.instance_subnet_ids}"]  
}

# Security group for elb

resource "aws_security_group" "lb_sg" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "elb", "secgroup")))}"
  description = "Security Group for rstudio ELB instances"
  vpc_id      = "${var.vpc_id}"

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
        join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "elb", "secgroup"))),
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


resource "aws_security_group_rule" "allow_all_lb_ingress" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  cidr_blocks     = ["0.0.0.0/32"]  

  security_group_id = "${aws_security_group.lb_sg.id}"
}

resource "aws_security_group_rule" "allow_all_lb_egress" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  cidr_blocks     = ["0.0.0.0/32"]  

  security_group_id = "${aws_security_group.lb_sg.id}"
}

resource "aws_security_group_rule" "ec2_egress" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  source_security_group_id = "${aws_security_group.instance.id}"

  security_group_id = "${aws_security_group.lb_sg.id}"
}

# DNS entry for elb

resource "aws_route53_record" "lb_record" {
  zone_id = "${var.hosted_zone_id}"
  name    = "rstudio.${var.customer}.${var.environment}.${var.project}.local"
  type    = "A"  
  
  alias {
    name                   = "${aws_lb.rstudio_ecs_lb.dns_name}"
    zone_id                = "${aws_lb.rstudio_ecs_lb.zone_id}"
    evaluate_target_health = false
  }
}
