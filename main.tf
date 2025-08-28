terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# AWS Provider Configuration
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
  
  labels = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "google_storage_bucket_versioning" "example_bucket_versioning" {
  bucket = google_storage_bucket.example_bucket.id
  versioning {
    enabled = true
  }
}
