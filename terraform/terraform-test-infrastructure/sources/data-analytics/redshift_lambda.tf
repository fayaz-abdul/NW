data "aws_redshift_cluster" "this" {
  depends_on         = ["module.analytics_module_redshift"]
  cluster_identifier = "${var.environment}-${var.customer}-${var.project}-${var.role}-${var.application}-redshift"
}

resource "aws_iam_role" "RedshiftVpcRoutingRole" {
  name = "${join(var.delimiter, compact(list(var.environment, var.customer, var.project, var.role, var.application, "vpcroutingrole", "iamrole")))}"
  path = "${join("/", compact(list("/",var.environment, var.customer, var.project, var.role, var.application,"/")))}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "RedshiftVpcLambdaAccess"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "RedshiftVpcRoutingPolicy" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "Redshift", "VpcRouting", "Policy")))}"
  description = "A Data Analytics Redshift Vpc Routing policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "redshift:ModifyCluster"
      ],
      "Resource": [
        "arn:aws:redshift:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:cluster:${data.aws_redshift_cluster.this.cluster_identifier}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "redshift:DescribeClusters"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "RedshiftVpcRouting_policy_attachments" {
  role       = "${aws_iam_role.RedshiftVpcRoutingRole.name}"
  policy_arn = "${aws_iam_policy.RedshiftVpcRoutingPolicy.arn}"
}

resource "aws_lambda_function" "RedshiftVpcRoutingLambda" {
  count             = "${var.analytics_redshift_lambdaversionid == "undefined" ? 0 : 1 }"
  description       = "${join(var.delimiter, compact(list("CloudFormation Lambda function to set vpc routing on the", var.application, var.role)))}"
  function_name     = "${join(var.delimiter, compact(list(var.environment, var.customer, var.project, var.role, var.application, "_redshiftvpcrouting_cflambda")))}"
  role              = "${aws_iam_role.RedshiftVpcRoutingRole.arn}"
  handler           = "index.handler"
  s3_bucket         = "${var.analytics_redshift_lambdafunctioncodebucket}"
  s3_key            = "${var.analytics_redshift_lambdafunctioncodekey}"
  s3_object_version = "${var.analytics_redshift_lambdaversionid}"
  runtime           = "nodejs8.10"
}

# RedshiftVpcRouting is pending becasue Custom::RedshiftVpcRoutingLambda coudn't find suitable resource in terrafrom 

