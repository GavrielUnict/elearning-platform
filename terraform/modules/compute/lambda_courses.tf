# Lambda: Create Course
resource "aws_lambda_function" "create_course" {
  filename         = "${path.module}/functions/create-course.zip"
  function_name    = "${var.project_name}-${var.environment}-create-course"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      COURSES_TABLE    = var.courses_table_name
      USER_POOL_ID     = var.user_pool_id
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/create-course.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-create-course"
  }
}

# Lambda: List Courses
resource "aws_lambda_function" "list_courses" {
  filename         = "${path.module}/functions/list-courses.zip"
  function_name    = "${var.project_name}-${var.environment}-list-courses"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      COURSES_TABLE     = var.courses_table_name
      ENROLLMENTS_TABLE = var.enrollments_table_name
      USER_POOL_ID      = var.user_pool_id
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/list-courses.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-list-courses"
  }
}

# Lambda: Manage Course (Get/Update/Delete)
resource "aws_lambda_function" "manage_course" {
  filename         = "${path.module}/functions/manage-course.zip"
  function_name    = "${var.project_name}-${var.environment}-manage-course"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  # runtime         = "nodejs18.x"
  runtime         = "nodejs16.x"
  timeout         = 30
  memory_size     = 256
  
  layers = [aws_lambda_layer_version.shared_layer.arn]
  
  environment {
    variables = {
      COURSES_TABLE = var.courses_table_name
      USER_POOL_ID  = var.user_pool_id
    }
  }
  
  source_code_hash = filebase64sha256("${path.module}/functions/manage-course.zip")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-manage-course"
  }
}

# CloudWatch Log Groups per Lambda
resource "aws_cloudwatch_log_group" "create_course_logs" {
  name              = "/aws/lambda/${aws_lambda_function.create_course.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "list_courses_logs" {
  name              = "/aws/lambda/${aws_lambda_function.list_courses.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "manage_course_logs" {
  name              = "/aws/lambda/${aws_lambda_function.manage_course.function_name}"
  retention_in_days = 7
}