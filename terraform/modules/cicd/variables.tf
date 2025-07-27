variable "project_name" {
  description = "Nome del progetto"
  type        = string
}

variable "environment" {
  description = "Nome dell'ambiente"
  type        = string
}

variable "notification_email" {
  description = "Email per notifiche pipeline"
  type        = string
  default     = ""
}

# GitHub variables
variable "github_repository" {
  description = "GitHub repository nel formato owner/repository"
  type        = string
}

variable "github_branch" {
  description = "Branch GitHub da monitorare"
  type        = string
  default     = "main"
}

# Frontend variables
variable "user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
}

variable "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  type        = string
}

variable "api_gateway_url" {
  description = "API Gateway URL"
  type        = string
}

variable "elastic_beanstalk_app_name" {
  description = "Nome applicazione Elastic Beanstalk"
  type        = string
}

variable "elastic_beanstalk_env_name" {
  description = "Nome ambiente Elastic Beanstalk"
  type        = string
}

# ECS variables
variable "ecr_repository_name" {
  description = "Nome del repository ECR"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Nome del cluster ECS"
  type        = string
}