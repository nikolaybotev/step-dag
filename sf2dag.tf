# Lambda Function for Triggering Airflow DAG
resource "aws_lambda_function" "trigger_dag_lambda" {
  filename         = "lambda/trigger_dag.zip"
  function_name    = "${var.project_name}-${var.environment}-trigger-dag"
  role            = aws_iam_role.trigger_dag_lambda_role.arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT_NAME = var.project_name
      GCP_PROJECT_ID = var.gcp_project_id
      GCP_REGION = var.gcp_region
      COMPOSER_ENVIRONMENT = "${var.project_name}-${var.environment}-composer"
      DAG_ID = "hello_world_dag"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-trigger-dag-lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for Trigger DAG Lambda (with WIF permissions)
resource "aws_iam_role" "trigger_dag_lambda_role" {
  name = "${var.project_name}-${var.environment}-trigger-dag-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-trigger-dag-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Trigger DAG Lambda
resource "aws_iam_role_policy_attachment" "trigger_dag_lambda_basic" {
  role       = aws_iam_role.trigger_dag_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Workload Identity Federation - AWS Identity Provider
resource "google_iam_workload_identity_pool" "aws_pool" {
  workload_identity_pool_id = "${var.project_name}-${var.environment}-aws-pool"
  display_name              = "AWS Workload Identity Pool"
  description               = "Identity pool for AWS Lambda to access Google Cloud"
}

# Workload Identity Federation - AWS Provider
resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.aws_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "aws-provider"
  
  aws {
    account_id = data.aws_caller_identity.current.account_id
  }
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.aws_role"   = "assertion.arn"
    "attribute.aws_account" = "assertion.account"
  }
  
  attribute_condition = "attribute.aws_account == \"${data.aws_caller_identity.current.account_id}\""
}

# Workload Identity Federation - Service Account
resource "google_service_account" "wif_service_account" {
  account_id   = "${var.project_name}-${var.environment}-wif-sa"
  display_name = "Workload Identity Federation Service Account"
  description  = "Service account for AWS Lambda to access Google Cloud APIs"
}

# IAM Policy Binding for WIF Service Account
resource "google_project_iam_member" "wif_composer_user" {
  project = var.gcp_project_id
  role    = "roles/composer.user"
  member  = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.aws_pool.name}/attribute.aws_role/${aws_iam_role.trigger_dag_lambda_role.arn}"
}

# IAM Policy Binding for WIF Service Account - Composer Worker
resource "google_project_iam_member" "wif_composer_worker" {
  project = var.gcp_project_id
  role    = "roles/composer.worker"
  member  = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.aws_pool.name}/attribute.aws_role/${aws_iam_role.trigger_dag_lambda_role.arn}"
}

# CloudWatch Log Group for Trigger DAG Lambda
resource "aws_cloudwatch_log_group" "trigger_dag_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.trigger_dag_lambda.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${var.environment}-trigger-dag-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}
