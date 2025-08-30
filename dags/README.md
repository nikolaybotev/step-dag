# Airflow DAGs

This directory contains Airflow DAGs for the step-dag project.

## Development

```bash
python3.12 -m venv .venv
pip intall -r requirements.txt
```

## DAGs Overview

### 1. hello_world_dag.py
A simple example DAG that demonstrates basic Airflow concepts. It can be triggered manually or by another DAG with parameters.

**Features:**
- Basic task dependencies
- Python and Bash operators
- Parameter handling from external triggers
- Configurable via DAG run configuration

**Tasks:**
- `start`: Dummy start task
- `hello_world`: Python task that prints hello message with optional parameters
- `print_timestamp`: Python task that prints current timestamp
- `bash_hello`: Bash task that prints hello from bash
- `end`: Dummy end task

### 2. pubsub_trigger_dag.py
A DAG that listens for Pub/Sub messages and triggers the `hello_world_dag` with parameters extracted from the messages.

**Features:**
- Pub/Sub sensor to listen for messages
- JSON parameter parsing from Pub/Sub messages
- Dynamic DAG triggering with parameters
- Error handling for malformed messages
- XCom-based parameter passing

**Tasks:**
- `start`: Dummy start task
- `listen_pubsub`: Pub/Sub sensor that waits for messages
- `process_pubsub_message`: Processes and validates Pub/Sub message content
- `create_trigger_config`: Creates configuration for triggering hello_world_dag
- `trigger_hello_world_dag`: Triggers the hello_world_dag with parameters
- `end`: Dummy end task

## How It Works

1. **Pub/Sub Message**: A message is published to a Pub/Sub topic with JSON parameters
2. **Sensor Activation**: The `pubsub_trigger_dag` detects the message via its Pub/Sub sensor
3. **Message Processing**: The message is decoded and parsed for JSON parameters
4. **DAG Triggering**: The `hello_world_dag` is triggered with the extracted parameters
5. **Parameter Usage**: The `hello_world_dag` uses the parameters in its tasks

## Setup Requirements

### 1. GCP Pub/Sub Configuration
- Create a Pub/Sub topic and subscription
- Configure the subscription name and project ID in `pubsub_trigger_dag.py`
- Ensure the Airflow service account has proper Pub/Sub permissions

### 2. Airflow Providers
Install the required Airflow providers:
```bash
pip install apache-airflow-providers-google-cloud
```

### 3. Configuration
Update the following in `pubsub_trigger_dag.py`:
- `subscription`: Your Pub/Sub subscription name
- `project_id`: Your GCP project ID

## Example Usage

### Publishing a Pub/Sub Message
```bash
# Using gcloud CLI
gcloud pubsub topics publish hello-world-trigger-topic \
  --message='{"custom_message": "Hello from external system!", "timestamp": "2024-01-15T10:30:00", "source": "api_gateway"}'
```

### Expected Message Format
```json
{
  "custom_message": "Custom message to display",
  "timestamp": "2024-01-15T10:30:00",
  "source": "external_system",
  "priority": "high",
  "user_id": "user123"
}
```

### DAG Execution Flow
1. `pubsub_trigger_dag` starts and waits for Pub/Sub messages
2. When a message arrives, it's processed and parameters extracted
3. `hello_world_dag` is triggered with the parameters
4. `hello_world_dag` executes with the custom parameters
5. Both DAGs complete successfully

## Monitoring and Debugging

### XCom Values
- Check XCom for `process_pubsub_message` task to see extracted parameters
- Check XCom for `create_trigger_config` task to see trigger configuration

### Logs
- Pub/Sub sensor logs show message reception
- Processing task logs show parameter extraction
- Trigger task logs show DAG triggering details

### Common Issues
1. **Permission Denied**: Ensure Airflow service account has Pub/Sub subscriber role
2. **Subscription Not Found**: Verify subscription name and project ID
3. **JSON Parse Error**: Check message format in Pub/Sub
4. **DAG Trigger Failed**: Verify hello_world_dag exists and is enabled

## Customization

### Adding New Parameters
1. Update the message processing logic in `process_pubsub_message`
2. Modify the `hello_world_dag` tasks to use new parameters
3. Update the example message format in documentation

### Multiple DAG Triggers
The `pubsub_trigger_dag` can be extended to trigger multiple DAGs based on message content by:
1. Adding message routing logic
2. Creating multiple trigger tasks
3. Using conditional task execution

### Error Handling
The current implementation includes basic error handling for:
- Missing messages
- JSON parsing errors
- Default parameter fallbacks

Extend error handling as needed for your use case.
