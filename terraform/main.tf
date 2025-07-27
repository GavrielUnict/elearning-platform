terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "elearning-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Moduli
module "networking" {
  source = "./modules/networking"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "cognito" {
  source = "./modules/cognito"
  
  project_name = var.project_name
  environment  = var.environment
  # domain_name  = var.domain_name
  # domain_name  = local.eb_domain # Rimosso non più necessario
}

module "storage" {
  source = "./modules/storage"
  
  project_name = var.project_name
  environment  = var.environment
  # domain_name  = var.domain_name
  # domain_name  = local.eb_domain # Rimosso non più necessario
}

# Messaging module
module "messaging" {
  source = "./modules/messaging"
  
  project_name = var.project_name
  environment  = var.environment
  admin_email  = var.admin_email
}

module "compute" {
  source = "./modules/compute"
  
  project_name = var.project_name
  environment  = var.environment
  
  # Cognito
  user_pool_id  = module.cognito.user_pool_id
  user_pool_arn = module.cognito.user_pool_arn
  
  # DynamoDB Tables
  courses_table_name     = module.storage.courses_table_name
  courses_table_arn      = module.storage.courses_table_arn
  enrollments_table_name = module.storage.enrollments_table_name
  enrollments_table_arn  = module.storage.enrollments_table_arn
  documents_table_name   = module.storage.documents_table_name
  documents_table_arn    = module.storage.documents_table_arn
  quizzes_table_name     = module.storage.quizzes_table_name
  quizzes_table_arn      = module.storage.quizzes_table_arn
  results_table_name     = module.storage.results_table_name
  results_table_arn      = module.storage.results_table_arn
  
  # S3 Buckets
  documents_bucket_name = module.storage.documents_bucket_name
  documents_bucket_arn  = module.storage.documents_bucket_arn

  # Add SNS topic ARN
  enrollment_notification_topic_arn = module.messaging.enrollment_notifications_topic_arn
}

# Compute ECS module
module "compute_ecs" {
  source = "./modules/compute_ecs"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  ecs_security_group_id = module.networking.ecs_security_group_id
  
  # DynamoDB Tables
  documents_table_name = module.storage.documents_table_name
  documents_table_arn  = module.storage.documents_table_arn
  quizzes_table_name   = module.storage.quizzes_table_name
  quizzes_table_arn    = module.storage.quizzes_table_arn
  
  # S3 Bucket
  documents_bucket_name = module.storage.documents_bucket_name
  documents_bucket_arn  = module.storage.documents_bucket_arn
  
  # SQS Queue
  document_processing_queue_arn = module.messaging.document_processing_queue_arn
  document_processing_queue_url = module.messaging.document_processing_queue_url
  
  depends_on = [module.messaging]
}

# Elastic Beanstalk module
module "elastic_beanstalk" {
  source = "./modules/elastic_beanstalk"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  
  user_pool_id        = module.cognito.user_pool_id
  user_pool_client_id = module.cognito.web_client_id
  api_gateway_url     = module.compute.api_gateway_invoke_url
  
  depends_on = [
    module.networking,
    module.cognito,
    module.compute
  ]
}

# CI/CD module
module "cicd" {
  source = "./modules/cicd"
  
  project_name       = var.project_name
  environment        = var.environment
  notification_email = var.admin_email
  
  # GitHub configuration
  github_repository = var.github_repository
  github_branch     = var.github_branch
  
  # Frontend variables
  user_pool_id        = module.cognito.user_pool_id
  user_pool_client_id = module.cognito.web_client_id
  api_gateway_url     = module.compute.api_gateway_invoke_url
  
  elastic_beanstalk_app_name = module.elastic_beanstalk.application_name
  elastic_beanstalk_env_name = module.elastic_beanstalk.environment_name
  
  # ECS variables
  ecr_repository_name = "${var.project_name}-${var.environment}-quiz-processor"
  ecs_cluster_name    = module.compute_ecs.ecs_cluster_name
  
  depends_on = [
    module.elastic_beanstalk,
    module.compute_ecs
  ]
}

# Outputs principali
output "vpc_id" {
  description = "ID del VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs delle subnet pubbliche"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs delle subnet private"
  value       = module.networking.private_subnet_ids
}