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

# Grant the pubsub.publisher role to the WIF Service Account
resource "google_pubsub_topic_iam_member" "wif_sa_pubsub_publisher" {
  topic  = google_pubsub_topic.hello_world_trigger_topic.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.wif_lambda_trigger_dag_sa.email}"
}

# Grant AWS IAM role permission to impersonate the GCP service account
# This allows the AWS Lambda (running with trigger_dag_lambda_role) to act as the GCP service account
resource "google_service_account_iam_member" "wif_pool_binding" {
  service_account_id = google_service_account.wif_lambda_trigger_dag_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.aws_pool.name}/attribute.aws_role/${aws_iam_role.trigger_dag_lambda_role.arn}"
}

# Generate Google Cloud client library configuration file for WIF
resource "local_file" "wif_sa_access" {
  filename = "${path.module}/lambda/trigger_dag/build/wif_sa_access.json"
  content  = <<EOF
{
  "universe_domain": "googleapis.com",
  "type": "external_account",
  "audience": "//iam.googleapis.com/${google_iam_workload_identity_pool.aws_pool.name}/providers/aws-provider",
  "subject_token_type": "urn:ietf:params:aws:token-type:aws4_request",
  "service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${google_service_account.wif_lambda_trigger_dag_sa.email}:generateAccessToken",
  "token_url": "https://sts.googleapis.com/v1/token",
  "credential_source": {
    "environment_id": "aws1",
    "region_url": "http://169.254.169.254/latest/meta-data/placement/availability-zone",
    "url": "http://169.254.169.254/latest/meta-data/iam/security-credentials",
    "regional_cred_verification_url": "https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15"
  }
}
EOF

  depends_on = [
    google_iam_workload_identity_pool.aws_pool,
    google_iam_workload_identity_pool_provider.aws_provider,
    google_service_account.wif_lambda_trigger_dag_sa
  ]
}
