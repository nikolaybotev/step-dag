# AWS Connection Setup for GCP Composer

This document explains how to set up the AWS connection in GCP Composer to enable triggering AWS Step Functions from Airflow DAGs.

## Prerequisites

1. Terraform has been applied to create the AWS IAM role and OIDC provider
2. The `aws_connection_config.json` file has been generated
3. Access to the GCP Composer environment

## Setup Steps

### 1. Access Composer Environment

Navigate to your GCP Composer environment in the Google Cloud Console:
- Go to Composer > Environments
- Click on your environment
- Click "Open Airflow UI"

### 2. Configure AWS Connection

1. In the Airflow UI, go to **Admin** > **Connections**
2. Click **+** to add a new connection
3. Configure the connection with the following details:

   **Connection Id**: `aws_default`
   
   **Connection Type**: `Amazon Web Services`
   
   **Extra** (JSON format):
   ```json
   {
     "role_arn": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/step-dag-dev-gcp-composer-sf-role",
     "region_name": "YOUR_AWS_REGION",
     "assume_role_method": "assume_role_with_web_identity",
     "assume_role_with_web_identity_federation": "google",
     "assume_role_with_web_identity_federation_audience": "https://www.googleapis.com/auth/cloud-platform",
   }
   ```

### 3. Set Environment Variables

Set the following environment variable in your Composer environment:

**Variable Name**: `AWS_STEP_FUNCTION_ARN`
**Value**: `arn:aws:states:us-east-1:YOUR_ACCOUNT_ID:stateMachine:step-dag-dev-hello-world-sf`

### 4. Alternative: Use Airflow Variables

Instead of environment variables, you can set Airflow variables:

1. Go to **Admin** > **Variables**
2. Add a new variable:
   - **Key**: `aws_step_function_arn`
   - **Value**: `arn:aws:states:us-east-1:YOUR_ACCOUNT_ID:stateMachine:step-dag-dev-hello-world-sf`

Then update the DAG to use:
```python
from airflow.models import Variable
state_machine_arn = Variable.get("aws_step_function_arn")
```

## Verification

1. Deploy the updated `hello_world_dag.py` to your Composer environment
2. Trigger the DAG manually or wait for the scheduled run
3. Check the task logs for the `trigger_aws_step_function` task
4. Verify in AWS Step Functions console that a new execution was started

## Troubleshooting

### Common Issues

1. **Authentication Error**: Verify the OIDC provider and IAM role are correctly configured
2. **Permission Denied**: Check that the IAM role has the necessary Step Functions permissions
3. **Connection Not Found**: Ensure the connection ID matches `aws_default` in the DAG
4. **Invalid ARN**: Verify the Step Function ARN is correct and accessible

### Debug Steps

1. Check Airflow logs for detailed error messages
2. Verify the AWS connection configuration in Airflow UI
3. Test the IAM role permissions in AWS Console
4. Check that the Composer service account has the correct unique ID

## Security Notes

- The WIF setup allows GCP Composer to assume AWS IAM roles without storing long-term credentials
- The OIDC provider validates that requests come from the specific GCP service account
- All communication is encrypted and follows AWS and GCP security best practices
