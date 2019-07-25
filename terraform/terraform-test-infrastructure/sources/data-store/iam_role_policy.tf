#---------------------------------- kinesis IAM  ----------------------------------
resource "aws_iam_role" "kinesis_iam_permissions" {
  name = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "kinesis", "IAM", "Roles")))}"
  path = "${join("/", compact(list("/",var.environment, var.customer, var.project, var.role, var.application,"/")))}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.KinesisStream_ExternalAccountId}:root"
      },
      "Sid": "kinesisstream"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "kinesispolicy" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "kinesis", "IAM", "policys")))}"
  description = "Data Store Firehose Access policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kinesis:PutRecord",
        "kinesis:PutRecords",
        "kinesis:DescribeStream"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "${module.store_source_s3copybucket.s3_bucket_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "${module.store_source_s3copybucket.s3_bucket_arn}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "kinesis_iam_policy_attachments" {
  depends_on = ["module.store_source_s3copybucket"]
  role       = "${aws_iam_role.kinesis_iam_permissions.name}"
  policy_arn = "${aws_iam_policy.kinesispolicy.arn}"
}

#---------------------------------- Lambda IAM roles and Access policy ----------------------------------
resource "aws_iam_role" "store_creates3copy_lambda" {
  name = "${join(var.delimiter, compact(list(var.environment, var.customer, var.project, var.role, var.application, "Copylambda", "iamroles")))}"
  path = "${join("/", compact(list("/", var.environment, var.customer, var.project, var.role, var.application, "/")))}"

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

resource "aws_iam_policy" "store_lambdas3" {
  depends_on  = ["module.store_source_s3copybucket"]
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "lambdas3", "IAM", "Policys")))}"
  description = "Data Store Lambda S3 Access policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:*"
      ],
      "Resource": "${module.store_redshiftkms.kms_key_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${module.store_source_s3copybucket.s3_bucket_arn}",
        "${module.store_source_s3copybucket.s3_bucket_arn}/*"
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
  depends_on = ["module.store_source_s3copybucket"]
  role       = "${aws_iam_role.store_creates3copy_lambda.name}"
  policy_arn = "${aws_iam_policy.store_lambdas3.arn}"
}

#---------------------------------- CRM KMS policy ----------------------------------
data "aws_iam_policy_document" "crm_kms" {
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
      identifiers = ["arn:aws:iam::${var.KinesisStream_ExternalAccountId}:root"]
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

#---------------------------------- KMS Firehouse policy ----------------------------------
data "aws_iam_policy_document" "kms_firehouse" {
  # depends_on = ["module.store_module_redshift"]
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
    #  values   = ["arn:aws:redshift:${data.aws_region.this.name}:cluster:${data.aws_redshift_cluster.test_cluster.cluster_identifier}"]
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

#---------------------------------- SFTP KMS policy ----------------------------------

data "aws_iam_policy_document" "sftp_kms" {
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
    #  values   = ["arn:aws:redshift:${data.aws_region.this.name}:cluster:${data.aws_redshift_cluster.test_cluster.cluster_identifier}"]
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

#---------------------------------- Redshit IAM Role   ----------------------------------
resource "aws_iam_role" "redshiftrole" {
  name = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "Redshift", "IAM", "Roles")))}"

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
  depends_on  = ["module.store_source_s3copybucket"]
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "Redshift", "IAM", "Policys")))}"
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
        "${module.store_source_s3copybucket.s3_bucket_arn}",
        "${module.store_source_s3copybucket.s3_bucket_arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "Red_shift_Iam_attach" {
  depends_on = ["module.store_source_s3copybucket"]
  role       = "${aws_iam_role.redshiftrole.name}"
  policy_arn = "${aws_iam_policy.redshiftpolicy.arn}"
}
