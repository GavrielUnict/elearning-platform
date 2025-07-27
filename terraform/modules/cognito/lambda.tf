# Lambda function per Post Confirmation
resource "aws_lambda_function" "post_confirmation" {
  filename         = "${path.module}/lambda-functions/post-confirmation.zip"
  function_name    = "${var.project_name}-${var.environment}-post-confirmation"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 10
  
  tags = {
    Name = "${var.project_name}-${var.environment}-post-confirmation"
  }
}

# Lambda function per Pre Authentication
resource "aws_lambda_function" "pre_authentication" {
  filename         = "${path.module}/lambda-functions/pre-authentication.zip"
  function_name    = "${var.project_name}-${var.environment}-pre-authentication"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 10
  
  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-pre-authentication"
  }
}

# IAM Role per Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-${var.environment}-cognito-lambda-role"
  
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
}

# Policy per Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-cognito-lambda-policy"
  role = aws_iam_role.lambda_execution_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminAddUserToGroup",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminUpdateUserAttributes"
        ]
        Resource = aws_cognito_user_pool.main.arn
      }
    ]
  })
}

# Permessi per Cognito di invocare Lambda
resource "aws_lambda_permission" "post_confirmation" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

resource "aws_lambda_permission" "pre_authentication" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_authentication.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "post_confirmation" {
  name              = "/aws/lambda/${aws_lambda_function.post_confirmation.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "pre_authentication" {
  name              = "/aws/lambda/${aws_lambda_function.pre_authentication.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "auth_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-auth-logs"
  retention_in_days = 30
}