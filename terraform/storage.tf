locals {
  s3_bucket_name = "${var.instance_alias}-artifacts"
}

resource "aws_s3_bucket" "connect_artifacts" {
  bucket        = local.s3_bucket_name
  force_destroy = true
}

resource "aws_s3_object" "folders" {
  for_each = toset([
    "chat_transcripts/",
    "call_recordings/",
    "reports/"
  ])

  bucket = aws_s3_bucket.connect_artifacts.id
  key    = each.key
}

# resource "aws_s3_bucket_versioning" "connect_artifacts" {
#   bucket = aws_s3_bucket.connect_artifacts.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

resource "aws_s3_bucket_server_side_encryption_configuration" "connect_artifacts" {
  bucket = aws_s3_bucket.connect_artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_alias.test.id
    }

    bucket_key_enabled = true
  }
}