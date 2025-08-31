# Grant the pubsub.publisher role to the AWS IAM role of the Trigger DAG Lambda.
resource "google_pubsub_topic_iam_member" "wif_direct_access_pubsub_publisher" {
  topic  = google_pubsub_topic.hello_world_trigger_topic.name
  role   = "roles/pubsub.publisher"
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.aws_pool.name}/attribute.aws_assumed_role/${aws_iam_role.lambda_role.name}/${aws_lambda_function.trigger_dag.function_name}"
}

# Grant the pubsub.publisher role to the AWS IAM role of the Trigger DAG Go Lambda.
resource "google_pubsub_topic_iam_member" "wif_direct_access_pubsub_publisher_go" {
  topic  = google_pubsub_topic.hello_world_trigger_topic.name
  role   = "roles/pubsub.publisher"
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.aws_pool.name}/attribute.aws_assumed_role/${aws_iam_role.lambda_role.name}/${aws_lambda_function.trigger_dag_go.function_name}"
}

# Generate Google Cloud client library configuration file for WIF
resource "local_file" "wif_direct_access" {
  filename = "${path.module}/lambda/trigger_dag/build/wif_direct_access.json"
  content  = <<EOF
{
  "universe_domain": "googleapis.com",
  "type": "external_account",
  "audience": "//iam.googleapis.com/${google_iam_workload_identity_pool.aws_pool.name}/providers/aws-provider",
  "subject_token_type": "urn:ietf:params:aws:token-type:aws4_request",
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
    google_iam_workload_identity_pool_provider.aws_provider
  ]
}
