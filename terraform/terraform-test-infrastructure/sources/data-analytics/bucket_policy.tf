resource "aws_s3_bucket_policy" "s3copybucketpolicy" {
  depends_on = ["module.analytics_source_s3copybucket"]
  bucket     = "${module.analytics_source_s3copybucket.s3_bucket_id}"

  policy = <<POLICY
{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Principal":"*","Action":"s3:PutObject","NotResource":"${module.analytics_source_s3copybucket.s3_bucket_arn}/firehose/redshift_processing/*/manifests/*","Condition":{"StringNotEquals":{"s3:x-amz-server-side-encryption":["aws:kms","AES256"]}}},{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::670426529310:root"},"Action":"s3:GetBucketLocation","Resource":"${module.analytics_source_s3copybucket.s3_bucket_arn}"},{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::670426529310:root"},"Action":"s3:ListBucket","Resource":"${module.analytics_source_s3copybucket.s3_bucket_arn}","Condition":{"StringEquals":{"s3:prefix":["","external/"]}}},{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::670426529310:root"},"Action":"s3:ListBucket","Resource":"${module.analytics_source_s3copybucket.s3_bucket_arn}","Condition":{"StringLike":{"s3:prefix":"external/crm/*"}}},{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::670426529310:root"},"Action":"s3:*","Resource":"${module.analytics_source_s3copybucket.s3_bucket_arn}/external/crm/*"},{"Effect":"Deny","Principal":{"AWS":"arn:aws:iam::670426529310:root"},"Action":"s3:PutObject","Resource":"${module.analytics_source_s3copybucket.s3_bucket_arn}/external/crm/*","Condition":{"StringNotEquals":{"s3:x-amz-acl":"bucket-owner-full-control"}}}]}
POLICY
}
