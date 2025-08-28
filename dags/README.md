# Airflow DAGs

This directory contains Airflow DAGs that will be deployed to Google Cloud Composer.

## Hello World DAG (`hello_world_dag.py`)

A simple example DAG that demonstrates basic Airflow concepts including:

- **Task Dependencies**: Sequential execution of tasks
- **Python Operators**: Custom Python functions for task logic
- **Bash Operators**: Shell command execution
- **Dummy Operators**: Placeholder tasks for workflow control
- **Scheduling**: Daily execution with catchup disabled

### DAG Structure

```
start → hello_world → print_timestamp → bash_hello → end
```

### Tasks

1. **start**: Dummy task that marks the beginning
2. **hello_world**: Python task that prints "Hello, World!"
3. **print_timestamp**: Python task that prints the current timestamp
4. **bash_hello**: Bash task that executes shell commands
5. **end**: Dummy task that marks completion

### Configuration

- **Schedule**: Runs daily at midnight
- **Start Date**: January 1, 2024
- **Retries**: 1 retry with 5-minute delay
- **Catchup**: Disabled to prevent backfilling

### Usage

After deployment to Composer:

1. The DAG will be automatically loaded from the Cloud Storage bucket
2. It will be paused by default (as configured in Terraform)
3. Enable the DAG in the Airflow web UI
4. Trigger manually or wait for scheduled execution

### Customization

To modify this DAG:

1. Edit the Python file locally
2. Run `terraform apply` to upload changes
3. The DAG will be automatically updated in Composer

### Monitoring

- Check task logs in the Airflow web UI
- Monitor execution history and performance
- Use Airflow's built-in monitoring and alerting features
