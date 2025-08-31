# Code archive for Timestamp Lambda
resource "archive_file" "timestamp_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/timestamp/build"
  output_path = "${path.module}/lambda/timestamp.zip"
}

# Lambda Function for Timestamp Task
resource "aws_lambda_function" "timestamp" {
  filename         = archive_file.timestamp_lambda.output_path
  source_code_hash = archive_file.timestamp_lambda.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-timestamp"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = var.lambda_runtime_python
  timeout          = 30

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-timestamp-lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for Timestamp Lambda
resource "aws_cloudwatch_log_group" "timestamp_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.timestamp.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${var.environment}-timestamp-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}
