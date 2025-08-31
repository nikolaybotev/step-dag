import json
import os
import logging
import boto3
from google.cloud import pubsub_v1

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to trigger an Airflow DAG by publishing a message to Pub/Sub.
    Uses Workload Identity Federation for authentication.
    
    Args:
        event: Input event from Step Function
        context: Lambda context object
    
    Returns:
        dict: Response with Pub/Sub publish status
    """
    logger.info('Trigger DAG Lambda function started')
    logger.info(f'Event: {json.dumps(event, indent=2)}')
    
    try:
        # Get caller identity to verify WIF is working
        client = boto3.client('sts')
        response = client.get_caller_identity()
        logger.info(f'Caller Identity: {response}')

        # Get environment variables
        pubsub_topic_id = os.environ.get('PUBSUB_TOPIC_ID')
        
        logger.info(f'Google Application Credentials: {os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")}')
        logger.info(f'Pub/Sub Topic: {pubsub_topic_id}')
        
        # Create Pub/Sub client
        publisher = pubsub_v1.PublisherClient()
        
        # Prepare the message data
        message_data = {
            "custom_message": f"Hello from AWS Step Function! Workflow: {event.get('workflow_id', 'unknown')}",
            "timestamp": context.get_remaining_time_in_millis() and str(context.get_remaining_time_in_millis()),
            "source": "aws_step_function",
            "workflow_id": event.get('workflow_id', 'unknown'),
            "execution_id": event.get('execution_id', 'unknown'),
            "lambda_request_id": context.aws_request_id,
            "trigger_time": context.get_remaining_time_in_millis() and str(context.get_remaining_time_in_millis())
        }
        
        # Convert to JSON string and encode as bytes
        message_json = json.dumps(message_data)
        message_bytes = message_json.encode('utf-8')
        
        logger.info(f'Publishing message to Pub/Sub: {message_json}')
        
        # Publish the message
        future = publisher.publish(pubsub_topic_id, data=message_bytes)
        message_id = future.result()  # Wait for the message to be published
        
        logger.info(f'Message published successfully with ID: {message_id}')
        
        result = {
            "message": f"Successfully published message to Pub/Sub topic: {pubsub_topic_id}",
            "message_id": message_id,
            "workflow_id": event.get('workflow_id', 'unknown'),
            "execution_id": event.get('execution_id', 'unknown'),
            "success": True
        }
        
        logger.info(f'Result: {json.dumps(result, indent=2)}')
        
        return result
        
    except Exception as error:
        error_class = error.__class__.__name__
        logger.error(f'Error in Trigger DAG Lambda: {error_class}: {error}')
        
        return {
            "message": "Error occurred while triggering DAG",
            "error": str(error),
            "error_class": error_class,
            "success": False
        }
