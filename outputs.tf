# AWS Outputs
output "aws_bucket_name" {
  description = "Name of the created AWS S3 bucket"
  value       = aws_s3_bucket.example_bucket.bucket
}

output "aws_bucket_arn" {
  description = "ARN of the created AWS S3 bucket"
  value       = aws_s3_bucket.example_bucket.arn
}

# GCP Outputs
output "gcp_bucket_name" {
  description = "Name of the created GCP Storage bucket"
  value       = google_storage_bucket.example_bucket.name
}

output "gcp_bucket_url" {
  description = "URL of the created GCP Storage bucket"
  value       = google_storage_bucket.example_bucket.url
}
