# Python Lambda Functions for Step Function

This directory contains the Python Lambda functions used by the AWS Step Function workflow.

## Functions

### 1. Hello World Lambda (`hello_world/index.py`)
- **Purpose**: First task in the workflow that returns a hello world message
- **Input**: Any event data from the Step Function
- **Output**: Message, timestamp, and environment information
- **Success**: Always returns `success: true`
- **Runtime**: Python 3.9

### 2. Timestamp Lambda (`timestamp/index.py`)
- **Purpose**: Second task that processes the output from the first task
- **Input**: Event data from the previous Lambda (includes message and timestamp)
- **Output**: Current timestamp, formatted date, and input processing results
- **Success**: Always returns `success: true`
- **Runtime**: Python 3.9

## Building the Lambda Functions

### Prerequisites
- Python 3.9+ installed
- pip available for dependency installation

### Build Commands
```bash
# Build all Lambda functions (includes dependencies)
python build.py

# Clean up build artifacts manually (optional)
rm -f hello_world.zip timestamp.zip trigger_dag.zip

# Clean up installed dependencies from source directories
python build.py --clean
```

### Build Output
The build process creates:
- `hello_world.zip` - Deployable package for the hello world Lambda
- `timestamp.zip` - Deployable package for the timestamp Lambda
- `trigger_dag.zip` - Deployable package for the trigger DAG Lambda

### Dependency Handling
- **Automatic Installation**: Dependencies are automatically installed from `requirements.txt`
- **Platform-Specific**: Uses `manylinux2014_x86_64` for AWS Lambda compatibility
- **Binary Only**: Installs pre-compiled packages to avoid compilation issues
- **Cleanup Option**: Use `python build.py --clean` to remove installed dependencies

## Python Features Used

- **Logging**: Structured logging with CloudWatch integration
- **Error Handling**: Try-catch blocks with proper error reporting
- **Environment Variables**: Access to Lambda environment variables
- **JSON Processing**: Native Python JSON handling
- **Date/Time**: Python datetime module for timestamp operations

## Deployment

The Lambda functions are automatically deployed by Terraform when you run:
```bash
terraform apply
```

Terraform will:
1. Create the Lambda functions using the zip files
2. Set up IAM roles and policies
3. Configure environment variables
4. Create CloudWatch log groups

## Testing

### Local Testing
You can test the functions locally by running:
```bash
# Test hello world function
cd hello_world
python -c "
import json
from index import lambda_handler
result = lambda_handler({}, {})
print(json.dumps(result, indent=2))
"

# Test timestamp function
cd ../timestamp
python -c "
import json
from index import lambda_handler
result = lambda_handler({'message': 'test', 'timestamp': '2024-01-01T00:00:00'}, {})
print(json.dumps(result, indent=2))
"
```

### Step Function Testing
After deployment, you can test the complete workflow:
1. Go to AWS Step Functions console
2. Find your state machine: `${project_name}-${environment}-hello-world-sf`
3. Click "Start execution"
4. Provide any input (optional)
5. Monitor the execution

## Workflow Flow

```
Start → HelloWorld Lambda → Wait (5s) → Timestamp Lambda → TriggerAirflowDAG → Choice → Success/Error
```

## Environment Variables

### Basic Lambda Functions (hello_world, timestamp)
- `ENVIRONMENT`: Current environment (dev, staging, prod)
- `PROJECT_NAME`: Name of the project

### Trigger DAG Lambda Function
- `ENVIRONMENT`: Current environment (dev, staging, prod)
- `PROJECT_NAME`: Name of the project
- `GCP_PROJECT_ID`: Google Cloud project ID
- `GCP_REGION`: Google Cloud region
- `COMPOSER_ENVIRONMENT`: Composer environment name
- `DAG_ID`: Airflow DAG ID to trigger
- `WIF_SERVICE_ACCOUNT`: Workload Identity Federation service account email

## Logging

All Lambda functions log to CloudWatch with:
- Function start/end events
- Input event data
- Output results
- Any errors that occur

## Error Handling

- Each Lambda has try-catch blocks
- Errors are logged to CloudWatch
- Step Function catches errors and routes to ErrorHandler state
- Failed executions are marked as failed in Step Function

## Python Best Practices

- **Type Hints**: Functions include proper docstrings
- **Error Handling**: Comprehensive exception handling
- **Logging**: Structured logging for debugging
- **Environment Variables**: Safe access with defaults
- **JSON Processing**: Proper serialization/deserialization
