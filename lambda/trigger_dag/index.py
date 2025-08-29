import json
import os
import logging
from google.cloud import orchestration_airflow_v1

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to trigger an Airflow DAG using Google Cloud Composer API.
    Uses Workload Identity Federation for authentication.
    
    Args:
        event: Input event from Step Function
        context: Lambda context object
    
    Returns:
        dict: Response with DAG trigger status
    """
    logger.info('Trigger DAG Lambda function started')
    logger.info(f'Event: {json.dumps(event, indent=2)}')
    
    try:
        # Get environment variables
        gcp_project_id = os.environ.get('GCP_PROJECT_ID')
        gcp_region = os.environ.get('GCP_REGION')
        composer_environment = os.environ.get('COMPOSER_ENVIRONMENT')
        dag_id = os.environ.get('DAG_ID')
        
        logger.info(f'GCP Project: {gcp_project_id}')
        logger.info(f'GCP Region: {gcp_region}')
        logger.info(f'Composer Environment: {composer_environment}')
        logger.info(f'DAG ID: {dag_id}')
        
        # Create Composer client
        client = orchestration_airflow_v1.EnvironmentsClient()
        
        # Format the environment name
        environment_name = f"projects/{gcp_project_id}/locations/{gcp_region}/environments/{composer_environment}"
        logger.info(f'Environment name: {environment_name}')
        
        # Get the environment to verify it exists
        try:
            environment = client.get_environment(name=environment_name)
            logger.info(f'Found Composer environment: {environment.name}')
        except Exception as e:
            logger.error(f'Error getting Composer environment: {e}')
            return {
                "message": f"Error getting Composer environment: {str(e)}",
                "success": False,
                "error": str(e)
            }
        
        # Create the DAG trigger request
        dag_trigger_request = orchestration_airflow_v1.DagRun(
            dag_id=dag_id,
            execution_date=None,  # Use current time
            conf=json.dumps({
                "triggered_by": "aws_step_function",
                "workflow_id": event.get('workflow_id', 'unknown'),
                "step_function_execution": event.get('execution_id', 'unknown')
            })
        )
        
        # Trigger the DAG
        logger.info(f'Triggering DAG: {dag_id}')
        dag_run = client.create_dag_run(
            parent=environment_name,
            dag_run=dag_trigger_request
        )
        
        logger.info(f'DAG triggered successfully: {dag_run.name}')
        
        result = {
            "message": f"Successfully triggered DAG: {dag_id}",
            "dag_run_name": dag_run.name,
            "dag_id": dag_id,
            "environment": composer_environment,
            "project": gcp_project_id,
            "region": gcp_region,
            "success": True
        }
        
        logger.info(f'Result: {json.dumps(result, indent=2)}')
        
        return result
        
    except Exception as error:
        logger.error(f'Error in Trigger DAG Lambda: {error}')
        
        return {
            "message": "Error occurred while triggering DAG",
            "error": str(error),
            "success": False
        }
