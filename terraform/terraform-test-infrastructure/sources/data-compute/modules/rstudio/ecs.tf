resource "aws_ecs_cluster" "cluster" {
  name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_task_definition" "rstudio_task" {
  family                = "${var.environment}_${var.customer}_${var.project}_${var.role}_${var.application}_rstudio_container_RStudioTaskDef"
  container_definitions = "${file("${path.module}/task_definitions/service.json")}"
  task_role_arn         = "${aws_iam_role.task_role.arn}"  
  execution_role_arn    = "${aws_iam_role.execution_role.arn}"  

  volume {
    name      = "rstudio-home"
    host_path = "/data/rstudio-home"
  }  
}

data "aws_iam_policy_document" "iam_exec_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio-exec", "iamrole")))}"
  assume_role_policy = "${data.aws_iam_policy_document.iam_exec_role.json}"
}

data "aws_iam_policy_document" "iam_task_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio-task", "iamrole")))}"
  assume_role_policy = "${data.aws_iam_policy_document.iam_task_role.json}"
}

resource "aws_ecs_service" "rstudio_service" {
  name            = "${var.environment}_${var.customer}_${var.project}_${var.role}_${var.application}_rstudio"
  cluster         = "${aws_ecs_cluster.cluster.id}"
  task_definition = "${aws_ecs_task_definition.rstudio_task.arn}"
  desired_count   = 1
  
  launch_type     = "EC2"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = 200

  load_balancer {
    target_group_arn = "${aws_lb_target_group.rstudio_ecs_tg.arn}"
    container_name   = "test_crimson_bi_data_compute_rstudio"
    container_port   = 8787
  }
}
