"""
Pub/Sub Trigger DAG
A DAG that listens for Pub/Sub messages and triggers the hello_world_dag with parameters.
"""

from datetime import datetime, timedelta
import json
import os
import base64
from airflow.decorators import dag, task
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

@dag(
    default_args=default_args,
    description='DAG that triggers hello_world_dag based on Pub/Sub messages',
    schedule_interval="@continuous",
    max_active_runs=1,
    catchup=False,
    tags=['pubsub', 'trigger', 'hello-world'],
)
def pubsub_trigger_dag():
    # Pull messages from Pub/Sub
    pull_pubsub_messages = PubSubPullSensor(
        task_id='pull_pubsub_messages',
        subscription=os.environ.get('PUBSUB_SUBSCRIPTION'),
        project_id=os.environ.get('GCP_PROJECT_ID'),
        ack_messages=True,
        deferrable=False,
        poke_interval=1,
        max_messages=1, # only one message at a time
    )

    # Parse the messages
    @task
    def parse_pubsub_message(messages):
        message_data = messages[0].get('message', {})
        decoded_data = base64.b64decode(message_data['data']).decode('utf-8')
        params = json.loads(decoded_data)
        print(f"Received parameters: {params}")
        return json.dumps(params)

    message = parse_pubsub_message(messages=pull_pubsub_messages.output)

    # Trigger the hello_world_dag
    TriggerDagRunOperator(
        task_id='trigger_hello_world_dag',
        trigger_dag_id='hello_world_dag',
        wait_for_completion=False,
        conf={
            'pubsub_params': message,
            'triggered_by': 'pubsub_trigger_dag',
            'trigger_time': '{{ ts }}'
        },
    )

pubsub_trigger_dag()
