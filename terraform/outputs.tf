# Output generali del progetto

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Nome dell'ambiente"
  value       = var.environment
}

# Networking outputs
output "vpc_details" {
  description = "Dettagli del VPC"
  value = {
    vpc_id               = module.networking.vpc_id
    vpc_cidr             = module.networking.vpc_cidr
    public_subnet_ids    = module.networking.public_subnet_ids
    private_subnet_ids   = module.networking.private_subnet_ids
    nat_gateway_id       = module.networking.nat_gateway_id
  }
}

output "security_groups" {
  description = "Security Group IDs"
  value = {
    alb_sg_id              = module.networking.alb_security_group_id
    elastic_beanstalk_sg_id = module.networking.elastic_beanstalk_security_group_id
    ecs_sg_id              = module.networking.ecs_security_group_id
    lambda_sg_id           = module.networking.lambda_security_group_id
    rds_sg_id              = module.networking.rds_security_group_id
  }
}

# Cognito outputs
output "cognito_details" {
  description = "Dettagli Cognito"
  value = {
    user_pool_id     = module.cognito.user_pool_id
    user_pool_arn    = module.cognito.user_pool_arn
    web_client_id    = module.cognito.web_client_id
    user_pool_domain = module.cognito.user_pool_domain
  }
  sensitive = true
}

# Storage outputs
output "storage_details" {
  description = "Dettagli Storage"
  value = {
    dynamodb_tables = {
      courses     = module.storage.courses_table_name
      enrollments = module.storage.enrollments_table_name
      documents   = module.storage.documents_table_name
      quizzes     = module.storage.quizzes_table_name
      results     = module.storage.results_table_name
    }
    s3_buckets = {
      documents     = module.storage.documents_bucket_name
      static_assets = module.storage.static_assets_bucket_name
    }
  }
}

# Compute outputs
output "api_details" {
  description = "Dettagli API"
  value = {
    api_gateway_url = module.compute.api_gateway_invoke_url
    api_stage       = module.compute.api_gateway_stage_name
  }
}

output "lambda_functions" {
  description = "Lambda Functions deployate"
  value       = module.compute.lambda_functions
  sensitive   = true
}

# ECS outputs
output "ecs_details" {
  description = "Dettagli ECS"
  value = {
    cluster_name      = module.compute_ecs.ecs_cluster_name
    ecr_repository    = module.compute_ecs.ecr_repository_url
    task_definition   = module.compute_ecs.task_definition_arn
  }
}

# CI/CD outputs
output "cicd_details" {
  description = "Dettagli CI/CD"
  value = {
    github_connection_arn    = module.cicd.github_connection_arn
    github_connection_status = module.cicd.github_connection_status
    pipelines = {
      frontend       = module.cicd.frontend_pipeline_name
      ecs           = module.cicd.ecs_pipeline_name
      infrastructure = module.cicd.infrastructure_pipeline_name
    }
  }
}

output "frontend_url" {
  description = "URL del frontend Elastic Beanstalk"
  value       = "http://${module.elastic_beanstalk.environment_url}"
}