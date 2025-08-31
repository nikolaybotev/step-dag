# Code archive for Hello World Lambda
resource "archive_file" "hello_world_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/hello_world/build"
  output_path = "${path.module}/lambda/hello_world.zip"
}

# Lambda Function for Hello World Task
resource "aws_lambda_function" "hello_world" {
  filename         = archive_file.hello_world_lambda.output_path
  source_code_hash = archive_file.hello_world_lambda.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-hello-world"
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
    Name        = "${var.project_name}-${var.environment}-hello-world-lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for Hello World Lambda
resource "aws_cloudwatch_log_group" "hello_world_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.hello_world.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${var.environment}-hello-world-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}
