provider "aws" {
  region = var.aws_region

  # You can add AWS credentials here or use environment variables
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
}

# GCP Provider Configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region

  # You can add GCP credentials here or use service account key file
  # credentials = file(var.gcp_credentials_file)
}
