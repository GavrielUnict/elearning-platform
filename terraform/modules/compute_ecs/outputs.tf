output "ecs_cluster_name" {
  description = "Nome del cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN del cluster ECS"
  value       = aws_ecs_cluster.main.arn
}

output "ecr_repository_url" {
  description = "URL del repository ECR"
  value       = aws_ecr_repository.quiz_processor.repository_url
}

output "task_definition_arn" {
  description = "ARN della task definition"
  value       = aws_ecs_task_definition.quiz_processor.arn
}

output "orchestrator_lambda_arn" {
  description = "ARN della Lambda orchestrator"
  value       = aws_lambda_function.ecs_orchestrator.arn
}

output "openai_secret_name" {
  description = "Nome del secret per OpenAI API key"
  value       = aws_secretsmanager_secret.openai_api_key.name
}