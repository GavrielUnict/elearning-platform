# API Gateway
output "api_gateway_id" {
  description = "ID dell'API Gateway"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_invoke_url" {
  description = "URL di invocazione dell'API Gateway"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_gateway_stage_name" {
  description = "Nome dello stage API Gateway"
  value       = aws_api_gateway_stage.main.stage_name
}

# Lambda Functions ARNs
output "lambda_functions" {
  description = "ARNs delle Lambda functions"
  value = {
    create_course       = aws_lambda_function.create_course.arn
    list_courses        = aws_lambda_function.list_courses.arn
    manage_course       = aws_lambda_function.manage_course.arn
    request_enrollment  = aws_lambda_function.request_enrollment.arn
    approve_enrollment  = aws_lambda_function.approve_enrollment.arn
    list_enrollments    = aws_lambda_function.list_enrollments.arn
    get_presigned_url   = aws_lambda_function.get_presigned_url.arn
    list_documents      = aws_lambda_function.list_documents.arn
    manage_document     = aws_lambda_function.manage_document.arn
    get_quiz           = aws_lambda_function.get_quiz.arn
    submit_quiz_results = aws_lambda_function.submit_quiz_results.arn
    list_results       = aws_lambda_function.list_results.arn
  }
}

# Lambda Layer
output "shared_layer_arn" {
  description = "ARN del Lambda Layer condiviso"
  value       = aws_lambda_layer_version.shared_layer.arn
}

# IAM Role
output "lambda_execution_role_arn" {
  description = "ARN del ruolo IAM per le Lambda functions"
  value       = aws_iam_role.lambda_execution_role.arn
}