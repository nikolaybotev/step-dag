# AWS Connection Configuration for GCP Composer
# This sets up the AWS connection with Google IdP credentials for triggering Step Functions

# Create a the AWS connection configuration in the Composer environment
# See https://airflow.apache.org/docs/apache-airflow-providers-amazon/stable/connections/aws.html#configuring-the-connection
module "composer_aws_connection" {
  source  = "terraform-google-modules/composer/google//modules/airflow_connection"
  version = "~> 6.2.0"

  project_id        = var.gcp_project_id
  composer_env_name = google_composer_environment.composer_env.name
  region            = var.gcp_region
  id                = "aws_default"
  type              = "aws"
  extra = {
    "role_arn"                                          = aws_iam_role.gcp_composer_step_function_role.arn
    "region_name"                                       = var.aws_region
    "assume_role_method"                                = "assume_role_with_web_identity"
    "assume_role_with_web_identity_federation"          = "google"
    "assume_role_with_web_identity_federation_audience" = "https://www.googleapis.com/auth/cloud-platform"
  }
}
