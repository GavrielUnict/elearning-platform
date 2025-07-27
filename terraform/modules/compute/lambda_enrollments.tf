# Lambda: Request Enrollment
resource "aws_lambda_function" "request_enrollment" {
  filename         = "${path.module}/functions/request-enrollment.zip"
  function_name    = "${var.project_name}-${var.environment}-request-enrollment"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      ENROLLMENTS_TABLE = var.enrollments_table_name
      COURSES_TABLE     = var.courses_table_name
      USER_POOL_ID      = var.user_pool_id
      SNS_TOPIC_ARN     = var.enrollment_notification_topic_arn
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/request-enrollment.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-request-enrollment"
  }
}

# Lambda: Approve Enrollment
resource "aws_lambda_function" "approve_enrollment" {
  filename         = "${path.module}/functions/approve-enrollment.zip"
  function_name    = "${var.project_name}-${var.environment}-approve-enrollment"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      ENROLLMENTS_TABLE = var.enrollments_table_name
      COURSES_TABLE     = var.courses_table_name
      USER_POOL_ID      = var.user_pool_id
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/approve-enrollment.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-approve-enrollment"
  }
}

# Lambda: List Enrollments
resource "aws_lambda_function" "list_enrollments" {
  filename         = "${path.module}/functions/list-enrollments.zip"
  function_name    = "${var.project_name}-${var.environment}-list-enrollments"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      ENROLLMENTS_TABLE = var.enrollments_table_name
      USER_POOL_ID      = var.user_pool_id
      COURSES_TABLE     = var.courses_table_name
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/list-enrollments.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-list-enrollments"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "request_enrollment_logs" {
  name              = "/aws/lambda/${aws_lambda_function.request_enrollment.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "approve_enrollment_logs" {
  name              = "/aws/lambda/${aws_lambda_function.approve_enrollment.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "list_enrollments_logs" {
  name              = "/aws/lambda/${aws_lambda_function.list_enrollments.function_name}"
  retention_in_days = 7
}

# IAM Policy aggiuntiva per SNS - sempre creata ma con statement condizionale
resource "aws_iam_role_policy" "lambda_sns_policy" {
  name = "${var.project_name}-${var.environment}-lambda-sns-policy"
  role = aws_iam_role.lambda_execution_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.enrollment_notification_topic_arn != "" ? var.enrollment_notification_topic_arn : "arn:aws:sns:*:*:non-existent-topic"
      }
    ]
  })
}