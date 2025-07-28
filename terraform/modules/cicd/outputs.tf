output "github_connection_arn" {
  description = "ARN della connessione GitHub"
  value       = aws_codestarconnections_connection.github.arn
}

output "github_connection_status" {
  description = "Status della connessione GitHub"
  value       = aws_codestarconnections_connection.github.connection_status
}

output "frontend_pipeline_name" {
  description = "Nome della pipeline frontend"
  value       = aws_codepipeline.frontend.name
}

output "ecs_pipeline_name" {
  description = "Nome della pipeline ECS"
  value       = aws_codepipeline.ecs.name
}

# output "infrastructure_pipeline_name" {
#   description = "Nome della pipeline infrastructure"
#   value       = aws_codepipeline.infrastructure.name
# }

output "pipeline_artifacts_bucket" {
  description = "Nome del bucket per artifacts delle pipeline"
  value       = aws_s3_bucket.pipeline_artifacts.id
}

output "pipeline_notifications_topic_arn" {
  description = "ARN del topic SNS per notifiche pipeline"
  value       = aws_sns_topic.pipeline_notifications.arn
}