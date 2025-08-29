# IAM Role for Trigger DAG Lambda (with WIF permissions)
resource "aws_iam_role" "trigger_dag_lambda_role" {
  name = "${var.project_name}-${var.environment}-trigger-dag-lambda-role"

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
    Name        = "${var.project_name}-${var.environment}-trigger-dag-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Trigger DAG Lambda
resource "aws_iam_role_policy_attachment" "trigger_dag_lambda_basic" {
  role       = aws_iam_role.trigger_dag_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
