resource "aws_lambda_function" "store_s3copylambda" {
  count             = "${var.store_lambda_code_versionid == "undefined" ? 0 : 1 }"
  description       = "${join(var.delimiter, compact(list("Copies data from one s3 location to another for the", var.application, var.role)))}"
  function_name     = "${join(var.delimiter, compact(list(var.environment, var.customer, var.project, var.role, var.application, "s3copy_s3lambda")))}"
  role              = "${aws_iam_role.store_creates3copy_lambda.arn}"
  handler           = "index.handler"
  s3_bucket         = "${var.store_lambdafunctioncodebucket}"
  s3_key            = "${var.store_lambdafunctioncodekey}"
  s3_object_version = "${var.store_lambda_code_versionid}"
  runtime           = "nodejs8.10"

  environment {
    variables = {
      BUCKET         = "${var.store_s3_copy_destination}"
      PREFIX         = "${var.store_s3_copy_destination_prefix}"
      SSE_KMS_KEY_ID = "${module.store_redshiftkms.kms_key_id}"
    }
  }
}

resource "aws_s3_bucket_notification" "lambda_notification" {
  depends_on = ["aws_lambda_function.store_s3copylambda"]
  count      = "${var.store_lambda_code_versionid == "undefined" ? 0 : 1 }"
  bucket     = "${module.store_source_s3copybucket.s3_bucket_id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.store_s3copylambda.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${var.store_s3_copy_source_prefix}"
    filter_suffix       = "*"
  }
}
