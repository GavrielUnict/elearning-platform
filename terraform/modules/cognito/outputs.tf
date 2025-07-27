output "user_pool_id" {
  description = "ID del Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN del Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Endpoint del Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "web_client_id" {
  description = "ID del client web Cognito"
  value       = aws_cognito_user_pool_client.web_client.id
}

output "user_pool_domain" {
  description = "Dominio del Cognito User Pool"
  value       = aws_cognito_user_pool_domain.main.domain
}