# AWS Step Function - Hello World Workflow
resource "aws_sfn_state_machine" "hello_world" {
  name     = "${var.project_name}-${var.environment}-hello-world-sf"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "A Hello World Step Function workflow with Airflow DAG trigger"
    StartAt = "HelloWorld"

    States = {
      "HelloWorld" = {
        Type     = "Task"
        Resource = aws_lambda_function.hello_world.arn
        Next     = "WaitState"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "ErrorHandler"
          }
        ]
      }

      "WaitState" = {
        Type    = "Wait"
        Seconds = 5
        Next    = "TimestampState"
      }

      "TimestampState" = {
        Type     = "Task"
        Resource = aws_lambda_function.timestamp.arn
        Next     = "TriggerAirflowDAGInit"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "ErrorHandler"
          }
        ]
      }

      "TriggerAirflowDAGInit" = {
        Type = "Pass"
        Parameters = {
          "retry_count": 0
        }
        ResultPath = "$.retry_count"
        Next = "WaitBeforeTriggerAirflowDAG"
      }

      "WaitBeforeTriggerAirflowDAG" = {
        Type    = "Wait"
        Seconds = 5
        Next    = "TriggerAirflowDAG"
      }

      "TriggerAirflowDAG" = {
        Type     = "Task"
        Resource = aws_lambda_function.trigger_dag_go.arn
        Next     = "CheckDAGTriggerResult"
        Retry = [
          {
            ErrorEquals = ["States.ALL"]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "ErrorHandler"
          }
        ]
      }

      "CheckDAGTriggerResult" = {
        Type = "Choice"
        Choices = [
          {
            Variable      = "$.success"
            BooleanEquals = true
            Next          = "SuccessState"
          }
        ]
        Default = "ShouldRetryAirflowDAG"
      }

      "ShouldRetryAirflowDAG" = {
        Type = "Choice"
        Choices = [
          {
            Variable        = "$.retry_count"
            NumericLessThan = 3
            Next            = "IncrementRetryCountAirflowDAG"
          }
        ]
        Default = "ErrorHandler"
      }

      "IncrementRetryCountAirflowDAG" = {
        Type = "Pass"
        Parameters = {
          "retry_count.$": "States.MathAdd($.retry_count, 1)"
          "workflow_id.$": "$.workflow_id"
          "execution_id.$": "$.execution_id"
        }
        Next = "WaitBeforeTriggerAirflowDAG"
      }

      "SuccessState" = {
        Type    = "Succeed"
        Comment = "Workflow completed successfully"
      }

      "ErrorHandler" = {
        Type  = "Fail"
        Cause = "An error occurred during execution"
        Error = "WorkflowError"
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-hello-world-sf"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "hello-world-workflow"
  }
}

# IAM Role for Step Function
resource "aws_iam_role" "step_function_role" {
  name = "${var.project_name}-${var.environment}-step-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-step-function-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Step Function
resource "aws_iam_role_policy" "step_function_policy" {
  name = "${var.project_name}-${var.environment}-step-function-policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.hello_world.arn,
          aws_lambda_function.timestamp.arn,
          aws_lambda_function.trigger_dag.arn
        ]
      }
    ]
  })
}
