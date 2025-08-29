# Workload Identity Federation - Service Account
# This is the GCP service account that the AWS Lambda will impersonate
resource "google_service_account" "wif_lambda_trigger_dag_sa" {
  account_id   = "${var.project_name}-${var.environment}-wif-aws-lambda"
  display_name = "Workload Identity Federation Service Account for AWS Lambda Trigger DAG"
  description  = "Service account for AWS Lambda to access Google Cloud APIs"
}

# Grant the composer.user role to the WIF service account
# This allows the service account to interact with Cloud Composer (Airflow)
resource "google_project_iam_member" "wif_lambda_trigger_dag_sa_composer_user" {
  project = var.gcp_project_id
  role    = "roles/composer.user"
  member  = "serviceAccount:${google_service_account.wif_lambda_trigger_dag_sa.email}"
}

# Grant AWS IAM role permission to impersonate the GCP service account
# This allows the AWS Lambda (running with trigger_dag_lambda_role) to act as the GCP service account
resource "google_service_account_iam_member" "wif_pool_binding" {
  service_account_id = google_service_account.wif_lambda_trigger_dag_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.aws_pool.name}/attribute.aws_role/${aws_iam_role.trigger_dag_lambda_role.arn}"
}
