# Description: Create IAM user with Local provider
# Version: 0.2
# Author: Karthikeyan
# Date: 2025-05-11

locals {
  tags = {
    "Name"        = "karthikeyan-test"
    "Environment" = "test"
    "Department"  = "devops"
    "userowner"   = "karthikeyan"
  }

  # These are now correctly set as empty lists if not used
  source_ips  = []
  source_vpce = []

  users = [
    {
      name = "karthikeyan-test"
      tags = {
        "Name"           = "karthikeyan-test"
        "Environment"    = "test"
        "Department"     = "devops"
        "userowner"      = "karthikeyan"
        "userowneremail" = ""
      }
      buckets = [
        "karthikeyan-test-bucket",
        "karthikeyan-test-bucket-1",
        "karthikeyan-test-bucket-2",
        "karthikeyan-test-bucket-3"
      ]
      source_ips = ["192.168.1.129/32"]
      source_vpce = [""]
    },
    {
      name = "karthikeyan-test-1"
      tags = {
        "Name"           = "karthikeyan-test-1"
        "Environment"    = "test"
        "Department"     = "devops"
        "userowner"      = "karthikeyan"
        "userowneremail" = ""
      }
      buckets = [
        "karthikeyan-dev-bucket",
        "karthikeyan-dev-bucket-1",
        "karthikeyan-dev-bucket-2",
        "karthikeyan-dev-bucket-3"
      ]
      source_ips = ["192.168.1.129/32"]
      source_vpce = [""]
    }
  ]
}

data "aws_iam_policy_document" "s3_bucket_policy_test" {
  for_each = { for user in local.users : user.name => user }

  statement {
    sid    = "AllowS3BucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:DeleteObjectVersion",
      "s3:GetBucketAcl"
    ]
    resources = flatten([
      for bucket in each.value.buckets : [
        "arn:aws:s3:::${bucket}",
        "arn:aws:s3:::${bucket}/*"
      ]
    ])
  }

  # Optional: Add access restrictions using conditions
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "aws:viaAWSService"
      values   = ["false"]
    }
    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = each.value.source_ips
    }
    condition {
      test     = "StringNotEqualsIfExists"
      variable = "aws:SourceVpce"
      values   = each.value.source_vpce
    }
  }
}

resource "aws_iam_user" "user_creation_test" {
  for_each = { for user in local.users : user.name => user }
  name     = each.value.name
  tags     = each.value.tags
}

resource "aws_iam_policy" "s3_bucket_policy_test" {
  for_each    = { for user in local.users : user.name => user }
  name        = "${each.value.name}-s3-bucket-policy"
  description = "S3 bucket policy for ${each.value.name}"
  policy      = data.aws_iam_policy_document.s3_bucket_policy_test[each.key].json
}

resource "aws_iam_user_policy_attachment" "s3_bucket_policy_test" {
  for_each   = { for user in local.users : user.name => user }
  user       = aws_iam_user.user_creation_test[each.key].name
  policy_arn = aws_iam_policy.s3_bucket_policy_test[each.key].arn
}
