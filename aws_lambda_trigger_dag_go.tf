# Code archive for Trigger DAG Go Lambda
resource "archive_file" "trigger_dag_go_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/trigger_dag_go/build"
  output_path = "${path.module}/lambda/trigger_dag_go.zip"

  depends_on = [
    local_file.wif_direct_access,
    local_file.wif_sa_access
  ]
}

# Lambda Function for Triggering Airflow DAG (Go implementation)
resource "aws_lambda_function" "trigger_dag_go" {
  filename         = archive_file.trigger_dag_go_lambda.output_path
  source_code_hash = archive_file.trigger_dag_go_lambda.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-trigger-dag-go"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main"
  runtime          = var.lambda_runtime_go
  timeout          = 60

  environment {
    variables = {
      ENVIRONMENT                    = var.environment
      PROJECT_NAME                   = var.project_name
      GOOGLE_APPLICATION_CREDENTIALS = "./wif_direct_access.json"
      GCP_PROJECT_ID                 = var.gcp_project_id
      PUBSUB_TOPIC_ID                = google_pubsub_topic.hello_world_trigger_topic.id
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-trigger-dag-go-lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for Trigger DAG Go Lambda
resource "aws_cloudwatch_log_group" "trigger_dag_go_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.trigger_dag_go.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${var.environment}-trigger-dag-go-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}
