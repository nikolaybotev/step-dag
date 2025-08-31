# Trigger DAG Go Lambda Function

This is a Go implementation of the trigger_dag Lambda function that publishes messages to Google Cloud Pub/Sub to trigger Airflow DAGs.

## Features

- Publishes messages to Google Cloud Pub/Sub
- Uses Workload Identity Federation for authentication
- Integrates with AWS Step Functions
- Provides detailed logging and error handling
- Returns structured JSON responses

## Prerequisites

- Go 1.25 or later
- AWS CLI configured
- Terraform for infrastructure deployment

## Building

1. Install dependencies:
   ```bash
   go mod tidy
   ```

2. Build the Lambda function:
   ```bash
   ./build.sh
   ```

The build script will:
- Create a `build` directory
- Copy WIF credential files
- Build the Go binary for Linux (required for AWS Lambda)
- Create a deployment package (`trigger_dag_go.zip`)

## Deployment

The Lambda function is deployed using Terraform. The configuration is in `aws_lambda_trigger_dag_go.tf`.

## Environment Variables

The Lambda function expects the following environment variables:

- `PUBSUB_TOPIC_ID`: The Google Cloud Pub/Sub topic ID
- `GCP_PROJECT_ID`: The Google Cloud project ID
- `GOOGLE_APPLICATION_CREDENTIALS`: Path to the WIF credentials file
- `ENVIRONMENT`: Environment name (e.g., dev, staging, prod)
- `PROJECT_NAME`: Project name

## Input Event Format

The Lambda function expects an event with the following structure:

```json
{
  "workflow_id": "string",
  "execution_id": "string"
}
```

## Response Format

The Lambda function returns a response with the following structure:

```json
{
  "message": "string",
  "message_id": "string",
  "workflow_id": "string",
  "execution_id": "string",
  "success": true,
  "error": "string (optional)",
  "error_class": "string (optional)"
}
```

## Dependencies

- `github.com/aws/aws-lambda-go`: AWS Lambda Go runtime
- `github.com/aws/aws-sdk-go`: AWS SDK for Go
- `cloud.google.com/go/pubsub`: Google Cloud Pub/Sub client
- `google.golang.org/api`: Google API client

## Differences from Python Version

- Uses Go's native JSON handling
- Different error handling patterns
- Uses Go's context for timeout management
- More explicit type definitions
- Different logging approach (uses Go's standard log package)
