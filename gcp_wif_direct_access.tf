# Grant the composer.user role directly to the AWS IAM role of the Trigger DAG Lambda.
resource "google_project_iam_member" "wif_lambda_trigger_dag_composer_user" {
  project = var.gcp_project_id
  role    = "roles/composer.user"
  member  = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.aws_pool.name}/attribute.aws_role/${aws_iam_role.trigger_dag_lambda_role.arn}"
}
