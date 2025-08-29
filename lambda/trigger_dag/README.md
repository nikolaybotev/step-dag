# Trigger DAG Lambda Function

This Lambda function triggers Airflow DAGs by publishing messages to Google Cloud Pub/Sub using Workload Identity Federation (WIF) for secure authentication between AWS and Google Cloud.

## How It Works

### 1. **Workload Identity Federation (WIF)**
- **AWS Lambda** authenticates with **Google Cloud** without sharing long-lived credentials
- Uses **AWS IAM roles** and **Google Cloud service accounts**
- Secure, short-lived token exchange between clouds

### 2. **Authentication Flow**
```
AWS Lambda → AWS IAM Role → Google Cloud WIF Pool → GCP Service Account → Composer API
```

### 3. **DAG Trigger Process**
1. Lambda receives event from Step Function
2. Uses WIF to authenticate with Google Cloud
3. Publishes message to Pub/Sub topic
4. Pub/Sub sensor in Airflow detects the message
5. Airflow DAG is triggered with the message parameters
6. Returns success/failure status

## Dependencies

### Python Packages
- `google-cloud-pubsub` - Pub/Sub API client
- `google-auth` - Authentication library
- `google-auth-httplib2` - HTTP transport for auth
- `google-api-core` - Core Google API functionality

### Environment Variables
- `GCP_PROJECT_ID` - Google Cloud project ID
- `PUBSUB_TOPIC_NAME` - Pub/Sub topic name (defaults to 'hello-world-dag-trigger')

## Configuration

### AWS IAM Role
The Lambda function uses a dedicated IAM role with:
- Basic Lambda execution permissions
- Workload Identity Federation trust relationship

### Google Cloud IAM
- **Workload Identity Pool**: Defines the federation relationship
- **Service Account**: Has Pub/Sub publisher permissions
- **IAM Bindings**: Links AWS roles to GCP permissions

## Usage

### From Step Function
The Lambda is called as part of the Step Function workflow:
```json
{
  "workflow_id": "step-function-execution-id",
  "execution_id": "unique-execution-id"
}
```

### Message Format
The Pub/Sub message contains:
```json
{
  "custom_message": "Hello from AWS Step Function! Workflow: {workflow_id}",
  "timestamp": "timestamp",
  "source": "aws_step_function",
  "workflow_id": "step-function-execution-id",
  "execution_id": "unique-execution-id",
  "lambda_request_id": "lambda-request-id",
  "trigger_time": "trigger-timestamp"
}
```

## Security Features

- **No long-lived credentials** stored in Lambda
- **Role-based access control** through IAM
- **Audit logging** for all DAG triggers
- **Secure token exchange** between clouds

## Error Handling

- **Authentication failures** are logged and reported
- **Pub/Sub API errors** are captured and returned
- **Network timeouts** are handled gracefully
- **Message publishing failures** are caught and reported

## Monitoring

- **CloudWatch logs** for Lambda execution
- **Google Cloud logs** for Pub/Sub API calls
- **Step Function execution history** for workflow tracking
- **Pub/Sub message delivery** and **DAG run history** in Airflow UI

## Troubleshooting

### Common Issues
1. **WIF authentication failures**: Check IAM role bindings
2. **Pub/Sub API errors**: Verify topic name and permissions
3. **Message not delivered**: Confirm topic exists and permissions are correct
4. **Timeout issues**: Check Lambda timeout and network connectivity

### Debug Steps
1. Check CloudWatch logs for Lambda execution
2. Verify WIF pool and provider configuration
3. Confirm Pub/Sub topic exists and permissions are correct
4. Test message publishing manually and check Airflow DAG execution
