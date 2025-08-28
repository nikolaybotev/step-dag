# AWS Outputs
output "aws_bucket_name" {
  description = "Name of the AWS S3 bucket"
  value       = aws_s3_bucket.example_bucket.bucket
}

output "aws_bucket_arn" {
  description = "ARN of the AWS S3 bucket"
  value       = aws_s3_bucket.example_bucket.arn
}

# Step Function Outputs
output "step_function_name" {
  description = "Name of the Step Function state machine"
  value       = aws_sfn_state_machine.hello_world_sf.name
}

output "step_function_arn" {
  description = "ARN of the Step Function state machine"
  value       = aws_sfn_state_machine.hello_world_sf.arn
}

output "step_function_url" {
  description = "URL to access the Step Function in AWS Console"
  value       = "https://console.aws.amazon.com/states/home?region=${var.aws_region}#/statemachines/view/${aws_sfn_state_machine.hello_world_sf.arn}"
}

# Lambda Function Outputs
output "hello_world_lambda_name" {
  description = "Name of the Hello World Lambda function"
  value       = aws_lambda_function.hello_world_lambda.function_name
}

output "hello_world_lambda_arn" {
  description = "ARN of the Hello World Lambda function"
  value       = aws_lambda_function.hello_world_lambda.arn
}

output "timestamp_lambda_name" {
  description = "Name of the Timestamp Lambda function"
  value       = aws_lambda_function.timestamp_lambda.function_name
}

output "timestamp_lambda_arn" {
  description = "ARN of the Timestamp Lambda function"
  value       = aws_lambda_function.timestamp_lambda.arn
}

# GCP Outputs
output "gcp_bucket_name" {
  description = "Name of the GCP Cloud Storage bucket"
  value       = google_storage_bucket.example_bucket.name
}

output "gcp_bucket_url" {
  description = "URL of the GCP Cloud Storage bucket"
  value       = google_storage_bucket.example_bucket.url
}

# Composer Outputs
output "composer_environment_name" {
  description = "Name of the Composer environment"
  value       = google_composer_environment.composer_env.name
}

output "composer_web_ui_url" {
  description = "Web UI URL for the Composer environment"
  value       = google_composer_environment.composer_env.config[0].airflow_uri
}

output "composer_gke_cluster" {
  description = "GKE cluster name for the Composer environment"
  value       = google_composer_environment.composer_env.config[0].gke_cluster
}

output "dags_bucket_name" {
  description = "Name of the Cloud Storage bucket for DAGs"
  value       = google_composer_environment.composer_env.config[0].dag_gcs_prefix
}

output "dags_bucket_url" {
  description = "URL of the Cloud Storage bucket for DAGs"
  value       = google_composer_environment.composer_env.config[0].dag_gcs_prefix
}

output "composer_service_account" {
  description = "Service account email for the Composer environment"
  value       = google_service_account.composer_sa.email
}
