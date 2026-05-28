# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Package the Lambda function code
data "archive_file" "python_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/../code/check_in_out_handler.py"
  output_path = "check_in_out_handler.zip"
}

# Lambda function — handles check-in and check-out activity recording
resource "aws_lambda_function" "test_lambda_function" {
  function_name    = "SEENCheckInOutHandler"
  filename         = data.archive_file.python_lambda_package.output_path
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.13"
  handler          = "check_in_out_handler.lambda_handler"
  timeout          = 5
}

# ── Validate Substation Lambda ────────────────────────────────────────────────

data "archive_file" "validate_substation_package" {
  type        = "zip"
  source_file = "${path.module}/../code/validate_substation.py"
  output_path = "${path.module}/validate_substation.zip"
}

resource "aws_lambda_function" "validate_substation" {
  function_name    = "SEENValidateSubstation"
  filename         = data.archive_file.validate_substation_package.output_path
  source_code_hash = data.archive_file.validate_substation_package.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.13"
  handler          = "validate_substation.lambda_handler"
  timeout          = 5
}

# Allow the Lambda role to read from the Substations and SeenIds tables
data "aws_iam_policy_document" "reference_tables_read" {
  statement {
    effect  = "Allow"
    actions = ["dynamodb:GetItem"]
    resources = [
      aws_dynamodb_table.substations_table.arn,
      aws_dynamodb_table.seen_ids_table.arn,
    ]
  }
}

resource "aws_iam_policy" "reference_tables_read" {
  name   = "SEENReferenceTablesReadPolicy"
  policy = data.aws_iam_policy_document.reference_tables_read.json
}

resource "aws_iam_role_policy_attachment" "reference_tables_read" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.reference_tables_read.arn
}

# ── Validate Substation — Connect wiring ─────────────────────────────────────

resource "aws_lambda_permission" "connect_validate_substation" {
  statement_id  = "AllowConnectInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validate_substation.function_name
  principal     = "connect.amazonaws.com"
  source_arn    = aws_connect_instance.test.arn
}

resource "aws_connect_lambda_function_association" "validate_substation" {
  instance_id  = aws_connect_instance.test.id
  function_arn = aws_lambda_function.validate_substation.arn
}

# ── Check-In/Out Handler — DynamoDB access + Connect wiring ──────────────────

data "aws_iam_policy_document" "seen_tracker_readwrite" {
  statement {
    effect  = "Allow"
    actions = ["dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:Query"]
    resources = [
      aws_dynamodb_table.seen_dynamodb_table.arn,
      "${aws_dynamodb_table.seen_dynamodb_table.arn}/index/*",
    ]
  }
}

resource "aws_iam_policy" "seen_tracker_readwrite" {
  name   = "SEENTrackerReadWritePolicy"
  policy = data.aws_iam_policy_document.seen_tracker_readwrite.json
}

resource "aws_iam_role_policy_attachment" "seen_tracker_readwrite" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.seen_tracker_readwrite.arn
}

resource "aws_lambda_permission" "connect_check_in_out" {
  statement_id  = "AllowConnectInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda_function.function_name
  principal     = "connect.amazonaws.com"
  source_arn    = aws_connect_instance.test.arn
}

resource "aws_connect_lambda_function_association" "check_in_out" {
  instance_id  = aws_connect_instance.test.id
  function_arn = aws_lambda_function.test_lambda_function.arn
}

# ── Get SEEN Status Lambda ────────────────────────────────────────────────────

data "archive_file" "get_seen_status_package" {
  type        = "zip"
  source_file = "${path.module}/../code/get_seen_status.py"
  output_path = "${path.module}/get_seen_status.zip"
}

resource "aws_lambda_function" "get_seen_status" {
  function_name    = "SEENGetStatus"
  filename         = data.archive_file.get_seen_status_package.output_path
  source_code_hash = data.archive_file.get_seen_status_package.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.13"
  handler          = "get_seen_status.lambda_handler"
  timeout          = 5
}

resource "aws_lambda_permission" "connect_get_seen_status" {
  statement_id  = "AllowConnectInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_seen_status.function_name
  principal     = "connect.amazonaws.com"
  source_arn    = aws_connect_instance.test.arn
}

resource "aws_connect_lambda_function_association" "get_seen_status" {
  instance_id  = aws_connect_instance.test.id
  function_arn = aws_lambda_function.get_seen_status.arn
}

# ── Validate SEEN ID Lambda ───────────────────────────────────────────────────

data "archive_file" "validate_seen_id_package" {
  type        = "zip"
  source_file = "${path.module}/../code/validate_seen_id.py"
  output_path = "${path.module}/validate_seen_id.zip"
}

resource "aws_lambda_function" "validate_seen_id" {
  function_name    = "SEENValidateSeenId"
  filename         = data.archive_file.validate_seen_id_package.output_path
  source_code_hash = data.archive_file.validate_seen_id_package.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.13"
  handler          = "validate_seen_id.lambda_handler"
  timeout          = 5
}

resource "aws_lambda_permission" "connect_validate_seen_id" {
  statement_id  = "AllowConnectInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validate_seen_id.function_name
  principal     = "connect.amazonaws.com"
  source_arn    = aws_connect_instance.test.arn
}

resource "aws_connect_lambda_function_association" "validate_seen_id" {
  instance_id  = aws_connect_instance.test.id
  function_arn = aws_lambda_function.validate_seen_id.arn
}

# ── List Active Check-ins Lambda (CLI only) ───────────────────────────────────

data "archive_file" "list_active_checkins_package" {
  type        = "zip"
  source_file = "${path.module}/../code/list_active_checkins.py"
  output_path = "${path.module}/list_active_checkins.zip"
}

resource "aws_lambda_function" "list_active_checkins" {
  function_name    = "SEENListActiveCheckIns"
  filename         = data.archive_file.list_active_checkins_package.output_path
  source_code_hash = data.archive_file.list_active_checkins_package.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.13"
  handler          = "list_active_checkins.lambda_handler"
  timeout          = 30
}