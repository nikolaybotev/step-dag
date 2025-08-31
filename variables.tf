variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "step-dag"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# AWS Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
  default     = ""
}

# GCP Variables
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = "your-gcp-project-id"
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-east4"
}

variable "gcp_credentials_file" {
  description = "Path to GCP service account key file"
  type        = string
  default     = ""
}

# Composer Variables
# See https://cloud.google.com/composer/docs/composer-versions#images-composer-3
variable "composer_image_version" {
  description = "Composer image version to use"
  type        = string
  default     = "composer-3-airflow-2.10.5" # uses python 3.11.8
}

variable "composer_environment_size" {
  description = "Size of the Composer environment (small, medium, large)"
  type        = string
  default     = "small"
}

variable "composer_node_count" {
  description = "Number of worker nodes for the Composer environment"
  type        = number
  default     = 1
}

# Lambda Variables
variable "lambda_runtime" {
  description = "Python runtime version for Lambda functions"
  type        = string
  default     = "python3.12"
}
variable "airflow_webserver_secret_key" {
  description = "Secret key for Airflow webserver security"
  type        = string
  sensitive   = true
  default     = "your-secret-key-here" # You'll need to set this in terraform.tfvars
}
