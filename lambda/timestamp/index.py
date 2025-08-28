import json
import os
from datetime import datetime
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Timestamp Lambda function for AWS Step Function workflow.
    
    Args:
        event: Input event from Step Function (includes output from previous Lambda)
        context: Lambda context object
    
    Returns:
        dict: Response with current timestamp, formatted date, and input processing
    """
    logger.info('Timestamp Lambda function started')
    logger.info(f'Event: {json.dumps(event, indent=2)}')
    
    try:
        # Get current timestamp and format it
        now = datetime.utcnow()
        timestamp = now.isoformat()
        
        # Format date in a human-readable way
        formatted_date = now.strftime('%B %d, %Y at %I:%M:%S %p UTC')
        
        # Process the input from previous step
        input_message = event.get('message', 'No message received')
        input_timestamp = event.get('timestamp', 'No timestamp received')
        
        result = {
            "message": f"Timestamp task completed at {formatted_date}",
            "currentTimestamp": timestamp,
            "formattedDate": formatted_date,
            "inputMessage": input_message,
            "inputTimestamp": input_timestamp,
            "environment": os.environ.get('ENVIRONMENT', 'unknown'),
            "project": os.environ.get('PROJECT_NAME', 'unknown'),
            "success": True
        }
        
        logger.info(f'Result: {json.dumps(result, indent=2)}')
        
        return result
        
    except Exception as error:
        logger.error(f'Error in Timestamp Lambda: {error}')
        
        return {
            "message": "Error occurred in Timestamp task",
            "error": str(error),
            "success": False
        }
