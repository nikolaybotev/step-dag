# Step Function Outputs
output "step_function_name" {
  description = "Name of the Step Function state machine"
  value       = aws_sfn_state_machine.hello_world.name
}

output "step_function_arn" {
  description = "ARN of the Step Function state machine"
  value       = aws_sfn_state_machine.hello_world.arn
}

output "step_function_url" {
  description = "URL to access the Step Function in AWS Console"
  value       = "https://console.aws.amazon.com/states/home?region=${var.aws_region}#/statemachines/view/${aws_sfn_state_machine.hello_world.arn}"
}

# Lambda Function Outputs
output "hello_world_lambda_name" {
  description = "Name of the Hello World Lambda function"
  value       = aws_lambda_function.hello_world.function_name
}

output "hello_world_lambda_arn" {
  description = "ARN of the Hello World Lambda function"
  value       = aws_lambda_function.hello_world.arn
}

output "timestamp_lambda_name" {
  description = "Name of the Timestamp Lambda function"
  value       = aws_lambda_function.timestamp.function_name
}

output "timestamp_lambda_arn" {
  description = "ARN of the Timestamp Lambda function"
  value       = aws_lambda_function.timestamp.arn
}

output "trigger_dag_lambda_name" {
  description = "Name of the Trigger DAG Lambda function"
  value       = aws_lambda_function.trigger_dag.function_name
}

output "trigger_dag_lambda_arn" {
  description = "ARN of the Trigger DAG Lambda function"
  value       = aws_lambda_function.trigger_dag.arn
}

# Workload Identity Federation Outputs
output "workload_identity_pool_id" {
  description = "Workload Identity Pool ID for AWS to GCP federation"
  value       = google_iam_workload_identity_pool.aws_pool.workload_identity_pool_id
}

output "workload_identity_pool_name" {
  description = "Workload Identity Pool name for AWS to GCP federation"
  value       = google_iam_workload_identity_pool.aws_pool.name
}

output "wif_service_account_email" {
  description = "Workload Identity Federation service account email"
  value       = google_service_account.wif_lambda_trigger_dag_sa.email
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

# Output the topic and subscription information
output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic for triggering DAGs"
  value       = google_pubsub_topic.hello_world_trigger_topic.name
}

output "pubsub_subscription_name" {
  description = "Name of the Pub/Sub subscription for triggering DAGs"
  value       = google_pubsub_subscription.hello_world_trigger_subscription.name
}

output "pubsub_topic_id" {
  description = "ID of the Pub/Sub topic for triggering DAGs"
  value       = google_pubsub_topic.hello_world_trigger_topic.id
}

output "pubsub_subscription_id" {
  description = "ID of the Pub/Sub subscription for triggering DAGs"
  value       = google_pubsub_subscription.hello_world_trigger_subscription.id
}

# AWS WIF for GCP to AWS Outputs
output "gcp_composer_step_function_role_arn" {
  description = "ARN of the IAM role for GCP Composer to trigger AWS Step Functions"
  value       = aws_iam_role.gcp_composer_step_function_role.arn
}

output "composer_service_account_unique_id" {
  description = "Unique ID of the Composer service account for WIF"
  value       = google_service_account.composer_sa.unique_id
}
