# AWS Step Function - Hello World Workflow
resource "aws_sfn_state_machine" "hello_world_sf" {
  name     = "${var.project_name}-${var.environment}-hello-world-sf"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "A Hello World Step Function workflow"
    StartAt = "HelloWorld"
    
    States = {
      "HelloWorld" = {
        Type = "Task"
        Resource = aws_lambda_function.hello_world_lambda.arn
        Next = "WaitState"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "ErrorHandler"
          }
        ]
      }
      
      "WaitState" = {
        Type = "Wait"
        Seconds = 5
        Next = "TimestampState"
      }
      
      "TimestampState" = {
        Type = "Task"
        Resource = aws_lambda_function.timestamp_lambda.arn
        Next = "ChoiceState"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "ErrorHandler"
          }
        ]
      }
      
      "ChoiceState" = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.success"
            BooleanEquals = true
            Next = "SuccessState"
          }
        ]
        Default = "ErrorHandler"
      }
      
      "SuccessState" = {
        Type = "Succeed"
        Comment = "Workflow completed successfully"
      }
      
      "ErrorHandler" = {
        Type = "Fail"
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
          aws_lambda_function.hello_world_lambda.arn,
          aws_lambda_function.timestamp_lambda.arn
        ]
      }
    ]
  })
}

# Lambda Function for Hello World Task
resource "aws_lambda_function" "hello_world_lambda" {
  filename         = "lambda/hello_world.zip"
  function_name    = "${var.project_name}-${var.environment}-hello-world"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT_NAME = var.project_name
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-hello-world-lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda Function for Timestamp Task
resource "aws_lambda_function" "timestamp_lambda" {
  filename         = "lambda/timestamp.zip"
  function_name    = "${var.project_name}-${var.environment}-timestamp"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT_NAME = var.project_name
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-timestamp-lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Lambda Functions
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group for Hello World Lambda
resource "aws_cloudwatch_log_group" "hello_world_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.hello_world_lambda.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${var.environment}-hello-world-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for Timestamp Lambda
resource "aws_cloudwatch_log_group" "timestamp_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.timestamp_lambda.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${var.environment}-timestamp-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}
