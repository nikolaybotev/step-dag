# AWS Step Function - Hello World End Workflow
resource "aws_sfn_state_machine" "hello_world_end" {
  name     = "${var.project_name}-${var.environment}-hello-world-end-sf"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "A Hello World End Step Function workflow with just one step"
    StartAt = "HelloWorld"

    States = {
      "HelloWorld" = {
        Type       = "Task"
        Resource   = aws_lambda_function.hello_world.arn
        ResultPath = "$.helloWorldResult"
        End        = true
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
    Name        = "${var.project_name}-${var.environment}-hello-world-end-sf"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "hello-world-end-workflow"
  }
}
