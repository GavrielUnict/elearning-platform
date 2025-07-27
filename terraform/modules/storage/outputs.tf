# DynamoDB Tables
output "courses_table_name" {
  description = "Nome della tabella DynamoDB Courses"
  value       = aws_dynamodb_table.courses.name
}

output "courses_table_arn" {
  description = "ARN della tabella DynamoDB Courses"
  value       = aws_dynamodb_table.courses.arn
}

output "enrollments_table_name" {
  description = "Nome della tabella DynamoDB Enrollments"
  value       = aws_dynamodb_table.enrollments.name
}

output "enrollments_table_arn" {
  description = "ARN della tabella DynamoDB Enrollments"
  value       = aws_dynamodb_table.enrollments.arn
}

output "documents_table_name" {
  description = "Nome della tabella DynamoDB Documents"
  value       = aws_dynamodb_table.documents.name
}

output "documents_table_arn" {
  description = "ARN della tabella DynamoDB Documents"
  value       = aws_dynamodb_table.documents.arn
}

output "quizzes_table_name" {
  description = "Nome della tabella DynamoDB Quizzes"
  value       = aws_dynamodb_table.quizzes.name
}

output "quizzes_table_arn" {
  description = "ARN della tabella DynamoDB Quizzes"
  value       = aws_dynamodb_table.quizzes.arn
}

output "results_table_name" {
  description = "Nome della tabella DynamoDB Results"
  value       = aws_dynamodb_table.results.name
}

output "results_table_arn" {
  description = "ARN della tabella DynamoDB Results"
  value       = aws_dynamodb_table.results.arn
}

# S3 Buckets
output "documents_bucket_name" {
  description = "Nome del bucket S3 per i documenti"
  value       = aws_s3_bucket.documents.id
}

output "documents_bucket_arn" {
  description = "ARN del bucket S3 per i documenti"
  value       = aws_s3_bucket.documents.arn
}

output "documents_bucket_regional_domain_name" {
  description = "Regional domain name del bucket documenti"
  value       = aws_s3_bucket.documents.bucket_regional_domain_name
}

output "static_assets_bucket_name" {
  description = "Nome del bucket S3 per gli asset statici"
  value       = aws_s3_bucket.static_assets.id
}

output "static_assets_bucket_arn" {
  description = "ARN del bucket S3 per gli asset statici"
  value       = aws_s3_bucket.static_assets.arn
}

output "static_assets_bucket_regional_domain_name" {
  description = "Regional domain name del bucket static assets"
  value       = aws_s3_bucket.static_assets.bucket_regional_domain_name
}

output "static_assets_website_endpoint" {
  description = "Website endpoint del bucket static assets"
  value       = aws_s3_bucket_website_configuration.static_assets.website_endpoint
}