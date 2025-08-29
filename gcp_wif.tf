# See https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Workload Identity Federation - AWS Workload Identity Pool
resource "google_iam_workload_identity_pool" "aws_pool" {
  workload_identity_pool_id = "${var.project_name}-${var.environment}-aws-pool"
  display_name              = "AWS Workload Identity Pool"
  description               = "Identity pool for AWS Lambda to access Google Cloud"
}

# Workload Identity Federation - AWS Workload Identity Pool - AWS Provider
resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.aws_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "aws-provider"

  aws {
    account_id = data.aws_caller_identity.current.account_id
  }

  attribute_mapping = {
    "google.subject"             = "assertion.arn"
    "attribute.aws_role"         = "assertion.arn.extract('assumed-role/{role}/')"
    "attribute.aws_assumed_role" = "assertion.arn.extract('assumed-role/{role_and_session}')"
    "attribute.aws_account"      = "assertion.account"
  }

  attribute_condition = "attribute.aws_account == \"${data.aws_caller_identity.current.account_id}\""
}
