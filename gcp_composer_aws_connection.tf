# AWS Connection Configuration for GCP Composer
# This sets up the AWS connection with WIF credentials for triggering Step Functions

# Create a local file with AWS connection configuration
# See https://airflow.apache.org/docs/apache-airflow-providers-amazon/stable/connections/aws.html#configuring-the-connection
resource "local_file" "aws_connection_config" {
  filename = "${path.module}/dags/aws_connection_config.json"
  content = jsonencode({
    "aws_default" = {
      "conn_type" = "aws"
      "extra" = {
        "role_arn" = aws_iam_role.gcp_composer_step_function_role.arn
        "region_name" = var.aws_region
        "assume_role_method" = "assume_role_with_web_identity"
        "assume_role_with_web_identity_federation" = "google"
        "assume_role_with_web_identity_federation_audience" = "https://www.googleapis.com/auth/cloud-platform"
      }
    }
  })

  depends_on = [
    aws_iam_role.gcp_composer_step_function_role,
    google_service_account.composer_sa
  ]
}

# Output the AWS connection configuration for reference
output "aws_connection_config" {
  description = "AWS connection configuration for Composer"
  value       = jsondecode(local_file.aws_connection_config.content)
  sensitive   = true
}
