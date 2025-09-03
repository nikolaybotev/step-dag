# AWS Lambda Function - Pub/Sub Step Function Trigger
resource "archive_file" "trigger_sf_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/trigger_sf/build"
  output_path = "${path.module}/lambda/trigger_sf.zip"

  depends_on = [
    local_file.wif_direct_access,
    local_file.wif_sa_access_sf
  ]
}

resource "aws_lambda_function" "trigger_sf_lambda" {
  filename         = archive_file.trigger_sf_lambda.output_path
  source_code_hash = archive_file.trigger_sf_lambda.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-trigger-sf"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = var.lambda_runtime_python
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      GOOGLE_APPLICATION_CREDENTIALS = "./wif_sa_access_sf.json"
      GOOGLE_CLOUD_PROJECT           = var.gcp_project_id
      PUBSUB_SUBSCRIPTION_PATH       = "projects/${var.gcp_project_id}/subscriptions/${google_pubsub_subscription.hello_world_sf_trigger_subscription.name}"
      STEP_FUNCTION_ARN              = aws_sfn_state_machine.hello_world_end.arn
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-trigger-sf-lambda"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "trigger-sf"
  }
}

# EventBridge Rule to trigger Lambda every minute
resource "aws_cloudwatch_event_rule" "trigger_sf_schedule" {
  name                = "${var.project_name}-${var.environment}-trigger-sf-schedule"
  description         = "Trigger Pub/Sub step function trigger Lambda every minute"
  schedule_expression = "rate(1 minute)"

  tags = {
    Name        = "${var.project_name}-${var.environment}-trigger-sf-schedule"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EventBridge Target to invoke the Lambda function
resource "aws_cloudwatch_event_target" "trigger_sf_target" {
  rule      = aws_cloudwatch_event_rule.trigger_sf_schedule.name
  target_id = "TriggerSFTarget"
  arn       = aws_lambda_function.trigger_sf_lambda.arn
}

# Lambda permission to allow EventBridge to invoke the function
resource "aws_lambda_permission" "trigger_sf_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_sf_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_sf_schedule.arn
}
