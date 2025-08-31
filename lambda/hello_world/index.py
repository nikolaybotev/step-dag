import json
import os
from datetime import datetime
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Hello World Lambda function for AWS Step Function workflow.
    
    Args:
        event: Input event from Step Function
        context: Lambda context object
    
    Returns:
        dict: Response with message, timestamp, and environment info
    """
    logger.info('Hello World Lambda function started')
    logger.info(f'Event: {json.dumps(event, indent=2)}')
    
    try:
        # Simulate some processing
        message = "Hello, World! This is a Step Function Lambda task."
        timestamp = datetime.now(datetime.timezone.utc).isoformat()
        
        result = {
            "message": message,
            "timestamp": timestamp,
            "environment": os.environ.get('ENVIRONMENT', 'unknown'),
            "project": os.environ.get('PROJECT_NAME', 'unknown'),
            "success": True
        }
        
        logger.info(f'Result: {json.dumps(result, indent=2)}')
        
        return result
        
    except Exception as error:
        logger.error(f'Error in Hello World Lambda: {error}')
        
        return {
            "message": "Error occurred in Hello World task",
            "error": str(error),
            "success": False
        }
