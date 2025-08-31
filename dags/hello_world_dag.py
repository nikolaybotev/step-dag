"""
Hello World Airflow DAG
A simple example DAG that demonstrates basic Airflow concepts.
"""

from datetime import datetime, timedelta
import json
import os
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.providers.amazon.aws.operators.step_function import StepFunctionStartExecutionOperator

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

# Define the DAG
dag = DAG(
    'hello_world_dag',
    default_args=default_args,
    description='A simple Hello World DAG',
    schedule_interval=timedelta(days=1),
    catchup=False,
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
        
        # Return dictionary with all data - this will be stored in XCom
        return {
            'message': f"Hello World completed successfully with custom message: {custom_message}",
            'workflow_id': workflow_id,
            'execution_id': execution_id + 1,
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

# AWS Step Function trigger task
trigger_aws_step_function = StepFunctionStartExecutionOperator(
    task_id='trigger_aws_step_function',
    state_machine_arn=os.environ.get('AWS_STEP_FUNCTION_ARN'),
    name='hello-world-from-gcp-{{ ts_nodash }}-{{ ti.xcom_pull(task_ids="hello_world").workflow_id }}-{{ ti.xcom_pull(task_ids="hello_world").execution_id }}',
    state_machine_input={
        'source': 'gcp-composer',
        'triggered_by': 'hello_world_dag',
        'trigger_time': '{{ ts }}',
        'dag_run_id': '{{ dag_run.run_id }}',
        'workflow_id': '{{ ti.xcom_pull(task_ids="hello_world").workflow_id }}',
        'execution_id': '{{ ti.xcom_pull(task_ids="hello_world").execution_id }}'
    },
    aws_conn_id='aws_default',  # This will use the WIF credentials
    dag=dag,
)

end_task = EmptyOperator(
    task_id='end',
    dag=dag,
)

# Define task dependencies
start_task >> hello_task >> timestamp_task >> bash_task >> trigger_aws_step_function >> end_task
