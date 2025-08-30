"""
Pub/Sub Trigger DAG
A DAG that listens for Pub/Sub messages and triggers the hello_world_dag with parameters.
"""

from datetime import datetime, timedelta
import json
import os
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.providers.google.cloud.sensors.pubsub import PubSubPullSensor

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
    'pubsub_trigger_dag',
    default_args=default_args,
    description='DAG that triggers hello_world_dag based on Pub/Sub messages',
    schedule_interval="@continuous",
    max_active_runs=1,
    catchup=False,
    tags=['pubsub', 'trigger', 'hello-world'],
)

# Define tasks
start_task = EmptyOperator(
    task_id='start',
    dag=dag,
)

def process_pubsub_message(**context):
    """
    Process the Pub/Sub message and extract parameters for hello_world_dag
    """
    # Get the message from the Pub/Sub sensor
    ti = context['ti']
    messages = ti.xcom_pull(task_ids='listen_pubsub')
    
    if not messages:
        raise ValueError("No messages received from Pub/Sub")
    
    # Process the first message (assuming single message processing)
    message = messages[0]
    message_data = message.get('message', {})
    
    # Decode the message data (assuming base64 encoded)
    import base64
    if 'data' in message_data:
        decoded_data = base64.b64decode(message_data['data']).decode('utf-8')
        try:
            # Parse JSON parameters
            params = json.loads(decoded_data)
            print(f"Received parameters: {params}")
            
            # Store parameters in XCom for the trigger task
            ti.xcom_push(key='dag_params', value=json.dumps(params))
            return json.dumps(params)
        except json.JSONDecodeError as e:
            print(f"Failed to parse JSON: {e}")
            # Use default parameters if JSON parsing fails
            default_params = {
                'custom_message': 'Default message from Pub/Sub',
                'timestamp': datetime.now().isoformat(),
                'source': 'pubsub_trigger_dag'
            }
            ti.xcom_push(key='dag_params', value=json.dumps(default_params))
            return json.dumps(default_params)
    else:
        # No data in message, use defaults
        default_params = {
            'custom_message': 'No data in Pub/Sub message',
            'timestamp': datetime.now().isoformat(),
            'source': 'pubsub_trigger_dag'
        }
        ti.xcom_push(key='dag_params', value=json.dumps(default_params))
        return json.dumps(default_params)

process_message_task = PythonOperator(
    task_id='process_pubsub_message',
    python_callable=process_pubsub_message,
    dag=dag,
)

# Pub/Sub sensor to listen for messages
pubsub_sensor = PubSubPullSensor(
    task_id='listen_pubsub',
    subscription=os.environ.get('PUBSUB_SUBSCRIPTION'),
    project_id=os.environ.get('GCP_PROJECT_ID'),
    ack_messages=True,
    deferrable=True,
    dag=dag,
)

# Trigger the hello_world_dag
trigger_hello_world = TriggerDagRunOperator(
    task_id='trigger_hello_world_dag',
    trigger_dag_id='hello_world_dag',
    conf={
        'pubsub_params': '{{ ti.xcom_pull(key="dag_params", task_ids="process_pubsub_message") }}',
        'triggered_by': 'pubsub_trigger_dag',
        'trigger_time': '{{ ts }}'
    },
    dag=dag,
)

end_task = EmptyOperator(
    task_id='end',
    dag=dag,
)

# Define task dependencies
start_task >> pubsub_sensor >> process_message_task >> trigger_hello_world >> end_task
