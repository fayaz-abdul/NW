#---------------------------------- Redshit IAM Role   ----------------------------------
resource "aws_iam_role" "redshiftrole" {
  name = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "Redshift", "IAM", "Role")))}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      },
      "Sid": "RedshiftAssumePolicy"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "redshiftpolicy" {
  depends_on  = ["module.analytics_source_s3copybucket"]
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "Redshift", "IAM", "Policy")))}"
  description = "A Redshift Access policy ${var.role} ${var.application}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${module.analytics_source_s3copybucket.s3_bucket_arn}",
        "${module.analytics_source_s3copybucket.s3_bucket_arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "Red_shift_Iam_attach" {
  depends_on = ["module.analytics_source_s3copybucket"]
  role       = "${aws_iam_role.redshiftrole.name}"
  policy_arn = "${aws_iam_policy.redshiftpolicy.arn}"
}

#---------------------------------- KMS Firehouse policy ----------------------------------
data "aws_iam_policy_document" "kms_firehouse" {
  statement = []

  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [true]
    }

    resources = ["*"]
  }

  statement {
    sid    = "Allow services use of the key"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"

      values = ["${data.aws_caller_identity.this.account_id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = ["redshift.${data.aws_region.this.name}:amazonaws.com"]
    }

    #condition {
    #  test     = "StringEquals"
    #  variable = "kms:EncryptionContext:aws:redshift:arn"
    #  values   = ["arn:aws:redshift:${data.aws_region.this.name}:cluster:${aws_redshift_cluster.this.cluster_identifier}"]
    #}

    resources = ["*"]
  }

  statement {
    sid    = "Allow use of the key" # KMS Key for use with Firehose
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["*"]
  }

  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }

    resources = ["*"]
  }

  statement {
    sid    = "Allow administration of the key"
    effect = "Allow"

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }

    resources = ["*"]
  }
}

#---------------------------------- RedShift KMS policy ----------------------------------
data "aws_iam_policy_document" "redshift_kms" {
  statement = []

  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [true]
    }

    resources = ["*"]
  }

  statement {
    sid    = "Allow services use of the key"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"

      values = ["${data.aws_caller_identity.this.account_id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = ["redshift.${data.aws_region.this.name}:amazonaws.com"]
    }

    resources = ["*"]
  }

  statement {
    sid    = "Allow use of the key" # Redshift
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["*"]
  }

  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }

    resources = ["*"]
  }

  statement {
    sid    = "Allow administration of the key"
    effect = "Allow"

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }

    resources = ["*"]
  }
}

#---------------------------------- Lambda IAM roles and Access policy ----------------------------------
resource "aws_iam_role" "analystics_creates3copy_lambda" {
  name = "${join(var.delimiter, compact(list(var.environment, var.customer, var.project, var.role, var.application, "Copylambda", "iamrole")))}"
  path = "${join("/", compact(list("/" , var.environment, var.customer, var.project, var.role, var.application, "/")))}"

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
      "Sid": "LambdaAccess"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "analystics_lambdas3" {
  depends_on  = ["module.analytics_source_s3copybucket"]
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "lambdas3", "IAM", "Policy")))}"
  description = "A Data Analytics Lambda S3 Access policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:*"
      ],
      "Resource": "${module.analytics_redshiftkms.kms_key_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${module.analytics_source_s3copybucket.s3_bucket_arn}",
        "${module.analytics_source_s3copybucket.s3_bucket_arn}/*"
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

resource "aws_iam_role_policy_attachment" "CreateS3Copy_policy_attachments" {
  depends_on = ["module.analytics_source_s3copybucket"]
  role       = "${aws_iam_role.analystics_creates3copy_lambda.name}"
  policy_arn = "${aws_iam_policy.analystics_lambdas3.arn}"
}

#TO do - tags

