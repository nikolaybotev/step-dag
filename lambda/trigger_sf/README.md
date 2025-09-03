# Pub/Sub Step Function Trigger Lambda

This Lambda function pulls messages from Google Cloud Pub/Sub and triggers AWS Step Functions with the message content as input.

## Functionality

- Polls Pub/Sub subscription every 10 seconds (via EventBridge rule)
- Pulls up to 10 messages per execution
- Parses JSON message content
- Triggers AWS Step Function with message content as input
- Acknowledges processed messages

## Environment Variables

- `PUBSUB_SUBSCRIPTION_PATH`: Full path to the Pub/Sub subscription (e.g., `projects/project-id/subscriptions/subscription-name`)
- `STEP_FUNCTION_ARN`: ARN of the AWS Step Function to trigger

## Input Format

The Lambda expects JSON messages in Pub/Sub with the following structure:
```json
{
  "workflow_id": "string",
  "execution_id": "string", 
  "custom_message": "string",
  "source": "string",
  "timestamp": "string",
  "trigger_type": "string"
}
```

## Output Format

The Step Function will receive input in the following format:
```json
{
  "source": "pubsub-lambda",
  "triggered_by": "pubsub_message", 
  "trigger_time": "number",
  "lambda_request_id": "string",
  "message_content": {
    // Original Pub/Sub message content
  }
}
```

## Deployment

1. Install dependencies: `pip install -r requirements.txt -t .`
2. Create ZIP file: `zip -r trigger_sf_lambda.zip .`
3. Deploy to AWS Lambda with EventBridge trigger (every 10 seconds)
