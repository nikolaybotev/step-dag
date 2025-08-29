# Code archive for Trigger DAG Lambda
resource "archive_file" "trigger_dag_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/trigger_dag/build"
  output_path = "${path.module}/lambda/trigger_dag.zip"

  depends_on = [
    local_file.wif_direct_access,
    local_file.wif_sa_access
  ]
}

# Lambda Function for Triggering Airflow DAG
resource "aws_lambda_function" "trigger_dag" {
  filename         = archive_file.trigger_dag_lambda.output_path
  source_code_hash = archive_file.trigger_dag_lambda.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-trigger-dag"
  role             = aws_iam_role.trigger_dag_lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = 60

  environment {
    variables = {
      ENVIRONMENT                    = var.environment
      PROJECT_NAME                   = var.project_name
      GOOGLE_APPLICATION_CREDENTIALS = "./wif_direct_access.json"
      GCP_PROJECT_ID                 = var.gcp_project_id
      GCP_REGION                     = var.gcp_region
      COMPOSER_ENVIRONMENT           = "${var.project_name}-${var.environment}-composer"
      DAG_ID                         = "hello_world_dag"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-trigger-dag-lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for Trigger DAG Lambda
resource "aws_cloudwatch_log_group" "trigger_dag_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.trigger_dag.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${var.environment}-trigger-dag-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}
