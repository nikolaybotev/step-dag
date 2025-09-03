"""
Hello World Airflow DAG
A simple example DAG that demonstrates basic Airflow concepts.
"""

from datetime import datetime, timedelta
import json
import os
import logging
from airflow import DAG
from airflow.decorators import task
from airflow.operators.python import get_current_context
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.providers.amazon.aws.operators.step_function import StepFunctionStartExecutionOperator
from airflow.providers.google.cloud.operators.pubsub import PubSubPublishMessageOperator

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Default arguments for the DAG
default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False, 
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def encode_message(message) -> bytes:
    print(f"Raw message: {message}")
    logger.info(f"Raw message: {message}")
    logger.info(f"Raw message type: {type(message)}")

    json_message = json.dumps(message)
    logger.info(f"Encoded message: {json_message}")
    logger.info(f"Encoded message type: {type(json_message)}")

    binary_encoded_message = json_message.encode('utf-8')
    logger.info(f"Binary encoded message: {binary_encoded_message}")
    logger.info(f"Binary encoded message type: {type(binary_encoded_message)}")
    return binary_encoded_message


# Define the DAG
dag = DAG(
    'hello_world_dag',
    default_args=default_args,
    description='A simple Hello World DAG',
    schedule_interval=timedelta(days=1),
    catchup=False,
    user_defined_macros={"encode_message": encode_message},
    tags=['example', 'hello-world'],
)

# Define tasks
start_task = EmptyOperator(
    task_id='start',
    dag=dag,
)

def print_hello(**context):
    """Print hello message with optional parameters from Pub/Sub"""
    # Get configuration parameters if triggered by another DAG
    conf = context.get('dag_run', {}).conf or {}
    pubsub_params = json.loads(conf.get('pubsub_params', {}))

    if pubsub_params:
        workflow_id = pubsub_params.get('workflow_id', 'unknown')
        execution_id = pubsub_params.get('execution_id', 'unknown')

        print(f"Workflow ID: {workflow_id}")
        print(f"Execution ID: {execution_id}")

        custom_message = pubsub_params.get('custom_message', 'Hello, World!')
        source = pubsub_params.get('source', 'unknown')
        trigger_time = pubsub_params.get('timestamp', 'unknown')
        print(f"Hello, World! This is a simple Airflow DAG.")
        print(f"Custom message: {custom_message}")
        print(f"Triggered by: {source}")
        print(f"Trigger time: {trigger_time}")
        
        # Safely increment execution_id, handling strings and non-numeric values
        try:
            int_execution_id = int(execution_id)
        except (ValueError, TypeError):
            # If conversion fails, coalesce to 0
            int_execution_id = 0
        
        # Return dictionary with all data - this will be stored in XCom
        return {
            'message': f"Hello World completed successfully with custom message: {custom_message}",
            'workflow_id': workflow_id,
            'execution_id': int_execution_id + 1,
            'custom_message': custom_message,
            'source': source,
            'trigger_time': trigger_time
        }
    else:
        print("Hello, World! This is a simple Airflow DAG.")
        return {
            'message': "Hello World completed successfully",
            'workflow_id': 'unknown',
            'execution_id': 'unknown'
        }

hello_task = PythonOperator(
    task_id='hello_world',
    python_callable=print_hello,
    dag=dag,
)

def print_timestamp(**context):
    """Print current timestamp with optional parameters from Pub/Sub"""
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"Current timestamp: {current_time}")
    
    # Get configuration parameters if triggered by another DAG
    conf = context.get('dag_run', {}).conf or {}
    pubsub_params = json.loads(conf.get('pubsub_params', {}))

    if pubsub_params:
        trigger_time = pubsub_params.get('timestamp', 'unknown')
        print(f"Pub/Sub trigger time: {trigger_time}")
        return f"Timestamp printed: {current_time} (triggered from Pub/Sub at {trigger_time})"
    else:
        return f"Timestamp printed: {current_time}"

timestamp_task = PythonOperator(
    task_id='print_timestamp',
    python_callable=print_timestamp,
    dag=dag,
)

bash_task = BashOperator(
    task_id='bash_hello',
    bash_command='echo "Hello from Bash operator!" && date',
    dag=dag,
)

# AWS Step Function trigger task (direct)
trigger_aws_step_function_direct = StepFunctionStartExecutionOperator(
    task_id='trigger_aws_step_function',
    state_machine_arn=os.environ.get('AWS_STEP_FUNCTION_ARN'),
    name='gcp-direct-{{ ts_nodash }}-{{ ti.xcom_pull(task_ids="hello_world").workflow_id|string|replace(" ", "_") }}-{{ ti.xcom_pull(task_ids="hello_world").execution_id|string|replace(" ", "_") }}',
    state_machine_input={
        'source': 'gcp-composer-direct',
        'triggered_by': 'hello_world_dag',
        'trigger_time': '{{ ts }}',
        'dag_run_id': '{{ dag_run.run_id }}',
        'workflow_id': '{{ ti.xcom_pull(task_ids="hello_world").workflow_id }}',
        'execution_id': '{{ ti.xcom_pull(task_ids="hello_world").execution_id }}',
        'custom_message': '{{ ti.xcom_pull(task_ids="hello_world").custom_message }}',
        'timestamp': '{{ ts }}',
        'trigger_type': 'direct'
    },
    aws_conn_id='aws_default',  # This will use the WIF credentials
    dag=dag,
)

@task
def create_pubsub_message():
    """Create Pub/Sub message with proper JSON encoding at runtime"""
    context = get_current_context()
    # Get XCom data from hello_world task
    hello_result = context['ti'].xcom_pull(task_ids='hello_world') or {}

    # Create the message data
    message_data = {
        'name': f"gcp-pubsub-{context['ts_nodash']}-{str(hello_result.get('workflow_id', 'unknown')).replace(' ', '_')}-{str(hello_result.get('execution_id', 'unknown')).replace(' ', '_')}",
        'source': 'hello_world_dag',
        'triggered_by': 'hello_world_dag',
        'trigger_time': context['ts'],
        'dag_run_id': context['dag_run'].run_id,
        'workflow_id': hello_result.get('workflow_id', 'unknown'),
        'execution_id': hello_result.get('execution_id', 'unknown'),
        'custom_message': hello_result.get('custom_message', ''), 
        'timestamp': context['ts'],
        'trigger_type': 'pubsub'
    }
    
    # Return the JSON-encoded message as bytes
    return message_data

pubsub_message = create_pubsub_message()

# AWS Step Function trigger task (Pub/Sub)
trigger_aws_step_function_pubsub = PubSubPublishMessageOperator(
    task_id='publish_pubsub_message',
    topic=os.environ.get('PUBSUB_TOPIC', 'hello-world-trigger-topic'),
    messages=[
        {
            "data": '{{ encode_message(ti.xcom_pull(task_ids="create_pubsub_message")) }}',
        },
    ],
    dag=dag,
)

end_task = EmptyOperator(
    task_id='end',
    dag=dag,
)

# Define task dependencies
bash_task >> pubsub_message
start_task >> hello_task >> timestamp_task >> bash_task >> [pubsub_message >> trigger_aws_step_function_pubsub, trigger_aws_step_function_direct] >> end_task
