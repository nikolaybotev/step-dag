# AWS IAM Role with WebIdentity for GCP to AWS authentication
# This allows GCP Composer to assume an AWS IAM role and trigger Step Functions

# OIDC Identity Provider for Google Cloud
resource "aws_iam_openid_connect_provider" "gcp_oidc" {
  url = "https://accounts.google.com"

  client_id_list = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]

  thumbprint_list = [
    "a031c46782e6e6c662c2c87c76da9aa62ccabd8e"  # Google's OIDC thumbprint
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-gcp-oidc"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "gcp-to-aws-federation"
  }
}

# IAM Role for GCP Composer to assume
resource "aws_iam_role" "gcp_composer_step_function_role" {
  name = "${var.project_name}-${var.environment}-gcp-composer-sf-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.gcp_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "accounts.google.com:aud" = "https://www.googleapis.com/auth/cloud-platform"
            "accounts.google.com:sub" = google_service_account.composer_sa.unique_id
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-gcp-composer-sf-role"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "gcp-composer-to-aws-sf"
  }
}

# IAM Policy for GCP Composer to trigger Step Functions
resource "aws_iam_role_policy" "gcp_composer_step_function_policy" {
  name = "${var.project_name}-${var.environment}-gcp-composer-sf-policy"
  role = aws_iam_role.gcp_composer_step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution",
          "states:DescribeExecution",
          "states:StopExecution"
        ]
        Resource = [
          aws_sfn_state_machine.hello_world.arn
        ]
      }
    ]
  })
}
