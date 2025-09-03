import json
import os
import logging
import boto3
from google.cloud import pubsub_v1
from google.pubsub_v1 import types
from google.auth import default

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function that pulls messages from Pub/Sub and triggers AWS Step Function
    """
    try:
        # Get configuration from environment variables
        subscription_path = os.environ.get('PUBSUB_SUBSCRIPTION_PATH')
        step_function_arn = os.environ.get('STEP_FUNCTION_ARN')
        
        if not subscription_path or not step_function_arn:
            raise ValueError("Missing required environment variables: PUBSUB_SUBSCRIPTION_PATH or STEP_FUNCTION_ARN")

        logger.info(f'Google Application Credentials: {os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")}')
        logger.info(f'Pub/Sub Subscription: {subscription_path}')
        logger.info(f'Step Function ARN: {step_function_arn}')

        # Initialize AWS Step Functions client
        sfn_client = boto3.client('stepfunctions')
        
        # Initialize Google Cloud Pub/Sub client
        credentials, project = default()
        subscriber = pubsub_v1.SubscriberClient(credentials=credentials)
        
        # Pull messages from Pub/Sub (max 10 messages at a time)
        request = types.pubsub.PullRequest(
            subscription=subscription_path,
            max_messages=10
        )
        
        response = subscriber.pull(request=request)
        
        if not response.received_messages:
            logger.info("No messages received from Pub/Sub")
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'No messages to process'})
            }
        
        processed_count = 0
        ack_ids = []
        
        for received_message in response.received_messages:
            try:
                # Decode the message data
                message_data = received_message.message.data.decode('utf-8')
                logger.info(f"Received message: {message_data}")
                
                # Parse the JSON message
                message_json = json.loads(message_data)
                
                # Generate a unique execution name
                execution_name = message_json.get('name', f"pubsub-lambda-{context.aws_request_id}-{processed_count}")
                
                # Trigger the Step Function with the message content as input
                step_function_input = message_json
                
                # Start Step Function execution
                response = sfn_client.start_execution(
                    stateMachineArn=step_function_arn,
                    name=execution_name,
                    input=json.dumps(step_function_input)
                )
                
                logger.info(f"Started Step Function execution: {response['executionArn']}")
                processed_count += 1
                
                # Add message to acknowledgment list
                ack_ids.append(received_message.ack_id)
                
            except json.JSONDecodeError as e:
                logger.error(f"Error parsing JSON message: {e}")
                # Still acknowledge the message to avoid infinite retries
                ack_ids.append(received_message.ack_id)
                
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                # Still acknowledge the message to avoid infinite retries
                ack_ids.append(received_message.ack_id)
        
        # Acknowledge all processed messages
        if ack_ids:
            ack_request = pubsub_v1.AcknowledgeRequest(
                subscription=subscription_path,
                ack_ids=ack_ids
            )
            subscriber.acknowledge(request=ack_request)
            logger.info(f"Acknowledged {len(ack_ids)} messages")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully processed {processed_count} messages',
                'processed_count': processed_count
            })
        }
        
    except Exception as e:
        logger.error(f"Error in lambda_handler: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
