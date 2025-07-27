# Lambda: Get Presigned URL
resource "aws_lambda_function" "get_presigned_url" {
  filename         = "${path.module}/functions/get-presigned-url.zip"
  function_name    = "${var.project_name}-${var.environment}-get-presigned-url"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      DOCUMENTS_BUCKET  = var.documents_bucket_name
      DOCUMENTS_TABLE   = var.documents_table_name
      COURSES_TABLE     = var.courses_table_name
      USER_POOL_ID      = var.user_pool_id
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/get-presigned-url.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-get-presigned-url"
  }
}

# Lambda: List Documents
resource "aws_lambda_function" "list_documents" {
  filename         = "${path.module}/functions/list-documents.zip"
  function_name    = "${var.project_name}-${var.environment}-list-documents"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      DOCUMENTS_TABLE   = var.documents_table_name
      ENROLLMENTS_TABLE = var.enrollments_table_name
      USER_POOL_ID      = var.user_pool_id
      COURSES_TABLE     = var.courses_table_name
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/list-documents.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-list-documents"
  }
}

# Lambda: Manage Document
resource "aws_lambda_function" "manage_document" {
  filename         = "${path.module}/functions/manage-document.zip"
  function_name    = "${var.project_name}-${var.environment}-manage-document"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      DOCUMENTS_TABLE   = var.documents_table_name
      DOCUMENTS_BUCKET  = var.documents_bucket_name
      COURSES_TABLE     = var.courses_table_name
      QUIZZES_TABLE     = var.quizzes_table_name
      USER_POOL_ID      = var.user_pool_id
      ENROLLMENTS_TABLE = var.enrollments_table_name
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/manage-document.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-manage-document"
  }
}

# Lambda: Get Quiz
resource "aws_lambda_function" "get_quiz" {
  filename         = "${path.module}/functions/get-quiz.zip"
  function_name    = "${var.project_name}-${var.environment}-get-quiz"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      QUIZZES_TABLE     = var.quizzes_table_name
      DOCUMENTS_TABLE   = var.documents_table_name
      ENROLLMENTS_TABLE = var.enrollments_table_name
      USER_POOL_ID      = var.user_pool_id
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/get-quiz.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-get-quiz"
  }
}

# Lambda: Submit Quiz Results
resource "aws_lambda_function" "submit_quiz_results" {
  filename         = "${path.module}/functions/submit-quiz-results.zip"
  function_name    = "${var.project_name}-${var.environment}-submit-quiz-results"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      RESULTS_TABLE     = var.results_table_name
      QUIZZES_TABLE     = var.quizzes_table_name
      ENROLLMENTS_TABLE = var.enrollments_table_name
      USER_POOL_ID      = var.user_pool_id
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/submit-quiz-results.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-submit-quiz-results"
  }
}

# Lambda: List Results
resource "aws_lambda_function" "list_results" {
  filename         = "${path.module}/functions/list-results.zip"
  function_name    = "${var.project_name}-${var.environment}-list-results"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      RESULTS_TABLE = var.results_table_name
      USER_POOL_ID  = var.user_pool_id
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/list-results.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-list-results"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "get_presigned_url_logs" {
  name              = "/aws/lambda/${aws_lambda_function.get_presigned_url.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "list_documents_logs" {
  name              = "/aws/lambda/${aws_lambda_function.list_documents.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "manage_document_logs" {
  name              = "/aws/lambda/${aws_lambda_function.manage_document.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "get_quiz_logs" {
  name              = "/aws/lambda/${aws_lambda_function.get_quiz.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "submit_quiz_results_logs" {
  name              = "/aws/lambda/${aws_lambda_function.submit_quiz_results.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "list_results_logs" {
  name              = "/aws/lambda/${aws_lambda_function.list_results.function_name}"
  retention_in_days = 7
}