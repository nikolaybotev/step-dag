# Trigger DAG Lambda Function

This Lambda function triggers Airflow DAGs in Google Cloud Composer using Workload Identity Federation (WIF) for secure authentication between AWS and Google Cloud.

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
3. Calls Composer API to trigger the specified DAG
4. Returns success/failure status

## Dependencies

### Python Packages
- `google-cloud-composer` - Composer API client
- `google-auth` - Authentication library
- `google-auth-httplib2` - HTTP transport for auth
- `google-api-core` - Core Google API functionality

### Environment Variables
- `GCP_PROJECT_ID` - Google Cloud project ID
- `GCP_REGION` - Google Cloud region
- `COMPOSER_ENVIRONMENT` - Composer environment name
- `DAG_ID` - Airflow DAG ID to trigger

## Configuration

### AWS IAM Role
The Lambda function uses a dedicated IAM role with:
- Basic Lambda execution permissions
- Workload Identity Federation trust relationship

### Google Cloud IAM
- **Workload Identity Pool**: Defines the federation relationship
- **Service Account**: Has Composer permissions
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

### DAG Configuration
The triggered DAG receives configuration:
```json
{
  "triggered_by": "aws_step_function",
  "workflow_id": "step-function-execution-id",
  "step_function_execution": "unique-execution-id"
}
```

## Security Features

- **No long-lived credentials** stored in Lambda
- **Role-based access control** through IAM
- **Audit logging** for all DAG triggers
- **Secure token exchange** between clouds

## Error Handling

- **Authentication failures** are logged and reported
- **Composer API errors** are captured and returned
- **Network timeouts** are handled gracefully
- **Invalid DAG IDs** are caught and reported

## Monitoring

- **CloudWatch logs** for Lambda execution
- **Google Cloud logs** for Composer API calls
- **Step Function execution history** for workflow tracking
- **DAG run history** in Airflow UI

## Troubleshooting

### Common Issues
1. **WIF authentication failures**: Check IAM role bindings
2. **Composer API errors**: Verify environment name and permissions
3. **DAG not found**: Confirm DAG ID and environment
4. **Timeout issues**: Check Lambda timeout and network connectivity

### Debug Steps
1. Check CloudWatch logs for Lambda execution
2. Verify WIF pool and provider configuration
3. Confirm Composer environment status
4. Test DAG trigger manually in Airflow UI
