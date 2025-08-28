# AWS Resources
resource "aws_s3_bucket" "example_bucket" {
  bucket = "${var.project_name}-${var.environment}-bucket"

  tags = {
    Name        = "${var.project_name}-${var.environment}-bucket"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "example_bucket_versioning" {
  bucket = aws_s3_bucket.example_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# GCP Resources
resource "google_storage_bucket" "example_bucket" {
  name          = "${var.project_name}-${var.environment}-bucket"
  location      = var.gcp_region
  force_destroy = true

  versioning {
    enabled = true
  }

  labels = {
    environment = var.environment
    project     = var.project_name
  }
}
