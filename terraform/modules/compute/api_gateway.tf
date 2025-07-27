# IAM Role per API Gateway CloudWatch Logs
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.project_name}-${var.environment}-api-gateway-cloudwatch-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# API Gateway Account Settings
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# API Gateway REST
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "E-Learning Platform API"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${var.project_name}-${var.environment}-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [var.user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# ====================
# COURSES RESOURCES
# ====================

# /courses
resource "aws_api_gateway_resource" "courses" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "courses"
}

# GET /courses
resource "aws_api_gateway_method" "list_courses" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.courses.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "list_courses" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.courses.id
  http_method = aws_api_gateway_method.list_courses.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_courses.invoke_arn
}

# POST /courses
resource "aws_api_gateway_method" "create_course" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.courses.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "create_course" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.courses.id
  http_method = aws_api_gateway_method.create_course.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_course.invoke_arn
}

# /courses/{courseId}
resource "aws_api_gateway_resource" "course" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.courses.id
  path_part   = "{courseId}"
}

# GET /courses/{courseId}
resource "aws_api_gateway_method" "get_course" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.course.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "get_course" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.course.id
  http_method = aws_api_gateway_method.get_course.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.manage_course.invoke_arn
}

# PUT /courses/{courseId}
resource "aws_api_gateway_method" "update_course" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.course.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "update_course" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.course.id
  http_method = aws_api_gateway_method.update_course.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.manage_course.invoke_arn
}

# DELETE /courses/{courseId}
resource "aws_api_gateway_method" "delete_course" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.course.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "delete_course" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.course.id
  http_method = aws_api_gateway_method.delete_course.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.manage_course.invoke_arn
}

# ====================
# ENROLLMENTS RESOURCES
# ====================

# /courses/{courseId}/enrollments
resource "aws_api_gateway_resource" "enrollments" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.course.id
  path_part   = "enrollments"
}

# GET /courses/{courseId}/enrollments
resource "aws_api_gateway_method" "list_enrollments" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.enrollments.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "list_enrollments" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.enrollments.id
  http_method = aws_api_gateway_method.list_enrollments.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_enrollments.invoke_arn
}

# POST /courses/{courseId}/enrollments
resource "aws_api_gateway_method" "request_enrollment" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.enrollments.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "request_enrollment" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.enrollments.id
  http_method = aws_api_gateway_method.request_enrollment.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.request_enrollment.invoke_arn
}

# /courses/{courseId}/enrollments/{enrollmentId}
resource "aws_api_gateway_resource" "enrollment" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.enrollments.id
  path_part   = "{enrollmentId}"
}

# PUT /courses/{courseId}/enrollments/{enrollmentId}
resource "aws_api_gateway_method" "approve_enrollment" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.enrollment.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "approve_enrollment" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.enrollment.id
  http_method = aws_api_gateway_method.approve_enrollment.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.approve_enrollment.invoke_arn
}

# ====================
# DOCUMENTS RESOURCES
# ====================

# /courses/{courseId}/documents
resource "aws_api_gateway_resource" "documents" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.course.id
  path_part   = "documents"
}

# GET /courses/{courseId}/documents
resource "aws_api_gateway_method" "list_documents" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.documents.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "list_documents" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.documents.id
  http_method = aws_api_gateway_method.list_documents.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_documents.invoke_arn
}

# POST /courses/{courseId}/documents
resource "aws_api_gateway_method" "get_upload_url" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.documents.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "get_upload_url" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.documents.id
  http_method = aws_api_gateway_method.get_upload_url.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_presigned_url.invoke_arn
}

# /courses/{courseId}/documents/{documentId}
resource "aws_api_gateway_resource" "document" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.documents.id
  path_part   = "{documentId}"
}

# GET /courses/{courseId}/documents/{documentId}
resource "aws_api_gateway_method" "get_download_url" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.document.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "get_download_url" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document.id
  http_method = aws_api_gateway_method.get_download_url.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.manage_document.invoke_arn
}

# DELETE /courses/{courseId}/documents/{documentId}
resource "aws_api_gateway_method" "delete_document" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.document.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "delete_document" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document.id
  http_method = aws_api_gateway_method.delete_document.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.manage_document.invoke_arn
}

# ====================
# QUIZ RESOURCES
# ====================

# /courses/{courseId}/documents/{documentId}/quiz
resource "aws_api_gateway_resource" "quiz" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.document.id
  path_part   = "quiz"
}

# GET /courses/{courseId}/documents/{documentId}/quiz
resource "aws_api_gateway_method" "get_quiz" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.quiz.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "get_quiz" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.quiz.id
  http_method = aws_api_gateway_method.get_quiz.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_quiz.invoke_arn
}

# POST /courses/{courseId}/documents/{documentId}/quiz
resource "aws_api_gateway_method" "submit_quiz" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.quiz.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "submit_quiz" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.quiz.id
  http_method = aws_api_gateway_method.submit_quiz.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.submit_quiz_results.invoke_arn
}

# ====================
# RESULTS RESOURCES
# ====================

# /results
resource "aws_api_gateway_resource" "results" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "results"
}

# GET /results
resource "aws_api_gateway_method" "list_results" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.results.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "list_results" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.results.id
  http_method = aws_api_gateway_method.list_results.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_results.invoke_arn
}

# ====================
# API DEPLOYMENT
# ====================

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  
  depends_on = [
    aws_api_gateway_integration.list_courses,
    aws_api_gateway_integration.create_course,
    aws_api_gateway_integration.get_course,
    aws_api_gateway_integration.update_course,
    aws_api_gateway_integration.delete_course,
    aws_api_gateway_integration.list_enrollments,
    aws_api_gateway_integration.request_enrollment,
    aws_api_gateway_integration.approve_enrollment,
    aws_api_gateway_integration.list_documents,
    aws_api_gateway_integration.get_upload_url,
    aws_api_gateway_integration.get_download_url,
    aws_api_gateway_integration.delete_document,
    aws_api_gateway_integration.get_quiz,
    aws_api_gateway_integration.submit_quiz,
    aws_api_gateway_integration.list_results,
    # CORS OPTIONS integrations
    aws_api_gateway_integration.courses_options,
    aws_api_gateway_integration.course_options,
    aws_api_gateway_integration.enrollments_options,
    aws_api_gateway_integration.enrollment_options,
    aws_api_gateway_integration.documents_options,
    aws_api_gateway_integration.document_options,
    aws_api_gateway_integration.quiz_options,
    aws_api_gateway_integration.results_options
  ]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment
  
  xray_tracing_enabled = false  # Può essere abilitato per debugging
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      error          = "$context.error.message"
    })
  }
  
  depends_on = [aws_api_gateway_account.main]
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 7
}

# Resource policy per permettere ad API Gateway di scrivere nei log
resource "aws_cloudwatch_log_resource_policy" "api_gateway_logs" {
  policy_name = "${var.project_name}-${var.environment}-api-gateway-logs-policy"
  
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda permissions per API Gateway
resource "aws_lambda_permission" "api_gateway_lambda" {
  for_each = {
    create_course       = aws_lambda_function.create_course.function_name
    list_courses        = aws_lambda_function.list_courses.function_name
    manage_course       = aws_lambda_function.manage_course.function_name
    request_enrollment  = aws_lambda_function.request_enrollment.function_name
    approve_enrollment  = aws_lambda_function.approve_enrollment.function_name
    list_enrollments    = aws_lambda_function.list_enrollments.function_name
    get_presigned_url   = aws_lambda_function.get_presigned_url.function_name
    list_documents      = aws_lambda_function.list_documents.function_name
    manage_document     = aws_lambda_function.manage_document.function_name
    get_quiz           = aws_lambda_function.get_quiz.function_name
    submit_quiz_results = aws_lambda_function.submit_quiz_results.function_name
    list_results       = aws_lambda_function.list_results.function_name
  }
  
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}