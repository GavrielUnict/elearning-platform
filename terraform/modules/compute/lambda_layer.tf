# Lambda Layer per utility functions condivise
resource "aws_lambda_layer_version" "shared_layer" {
  filename            = "${path.module}/layers/shared-layer.zip"
  layer_name          = "${var.project_name}-${var.environment}-shared-layer"
  # compatible_runtimes = ["nodejs18.x"]
  compatible_runtimes = ["nodejs16.x"]
  description         = "Shared utilities for Lambda functions"
  
  source_code_hash = filebase64sha256("${path.module}/layers/shared-layer.zip")
}

# IAM Role per tutte le Lambda functions
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-${var.environment}-lambda-execution-role"
  
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

# Policy per Lambda execution
resource "aws_iam_role_policy" "lambda_execution_policy" {
  name = "${var.project_name}-${var.environment}-lambda-execution-policy"
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
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          var.courses_table_arn,
          var.enrollments_table_arn,
          var.documents_table_arn,
          var.quizzes_table_arn,
          var.results_table_arn,
          "${var.courses_table_arn}/index/*",
          "${var.enrollments_table_arn}/index/*",
          "${var.results_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${var.documents_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.documents_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminGetUser",
          "cognito-idp:ListUsersInGroup"
        ]
        Resource = var.user_pool_arn
      }
    ]
  })
}

# Policy aggiuntiva per Lambda in VPC
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}