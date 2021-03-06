
# @Todo missing image 282376733589.dkr.ecr.eu-west-1.amazonaws.com/crimsonmacaw/r-mag-stn:rstan 
# and ecr repository crimsonmacaw in EU-west-1
resource "aws_ecs_task_definition" "ds_paxforecast_task" {
  family                = "${var.environment}-${var.customer}-${var.project}-${var.role}-${var.application}-ds-task-PaxForecastBatchTaskDef"
  container_definitions = "${file("${path.module}/task_definitions/batch_task_service.json")}"
  task_role_arn         = "${aws_iam_role.task_role.arn}"  
  execution_role_arn    = "${aws_iam_role.execution_role.arn}" 

  network_mode             = "awsvpc"
  requires_compatibilities = "FARGATE"
  cpu                      = 2048
  memory                   = 4096

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
  name               = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "ds-paxforecast-execution", "iamrole")))}"
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
  name               = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "ds-paxforecast-task", "iamrole")))}"
  assume_role_policy = "${data.aws_iam_policy_document.iam_task_role.json}"
}

