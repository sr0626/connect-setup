# KMS key policy permissions for the Connect service-linked role
# data "aws_iam_policy_document" "kms_policy" {
#   statement {
#     sid     = "AllowConnectUseOfKms"
#     effect  = "Allow"
#     principals {
#       type        = "AWS"
#       identifiers = [data.aws_iam_role.connect_slr.arn]
#     }
#     actions = [
#       "kms:Encrypt",
#       "kms:Decrypt",
#       "kms:GenerateDataKey*",
#       "kms:ReEncrypt*",
#       "kms:DescribeKey"
#     ]
#     resources = ["*"]
#   }
# }

# If you own/manage the CMK, attach/update this policy
# resource "aws_kms_key" "connect" {
#   description             = "CMK for Amazon Connect artifacts"
#   deletion_window_in_days = 7
#   policy                  = data.aws_iam_policy_document.kms_policy.json
# }
