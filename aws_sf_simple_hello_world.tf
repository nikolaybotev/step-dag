# AWS Step Function - Simple Hello World Workflow
resource "aws_sfn_state_machine" "simple_hello_world" {
  name     = "${var.project_name}-${var.environment}-simple-hello-world-sf"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "A simple Hello World Step Function workflow with just one step"
    StartAt = "HelloWorld"

    States = {
      "HelloWorld" = {
        Type     = "Task"
        Resource = aws_lambda_function.hello_world.arn
        ResultPath = "$.helloWorldResult"
        End     = true
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "ErrorHandler"
          }
        ]
      }

      "ErrorHandler" = {
        Type  = "Fail"
        Cause = "An error occurred during execution"
        Error = "WorkflowError"
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-simple-hello-world-sf"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "simple-hello-world-workflow"
  }
}
