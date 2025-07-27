variable "project_name" {
  description = "Nome del progetto"
  type        = string
}

variable "environment" {
  description = "Nome dell'ambiente"
  type        = string
}

variable "vpc_id" {
  description = "ID del VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs delle subnet private"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID del security group ECS"
  type        = string
}

# DynamoDB Tables
variable "documents_table_name" {
  description = "Nome della tabella DynamoDB Documents"
  type        = string
}

variable "documents_table_arn" {
  description = "ARN della tabella DynamoDB Documents"
  type        = string
}

variable "quizzes_table_name" {
  description = "Nome della tabella DynamoDB Quizzes"
  type        = string
}

variable "quizzes_table_arn" {
  description = "ARN della tabella DynamoDB Quizzes"
  type        = string
}

# S3 Bucket
variable "documents_bucket_name" {
  description = "Nome del bucket S3 per i documenti"
  type        = string
}

variable "documents_bucket_arn" {
  description = "ARN del bucket S3 per i documenti"
  type        = string
}

# SQS Queue
variable "document_processing_queue_arn" {
  description = "ARN della coda SQS per processamento documenti"
  type        = string
}

variable "document_processing_queue_url" {
  description = "URL della coda SQS per processamento documenti"
  type        = string
}