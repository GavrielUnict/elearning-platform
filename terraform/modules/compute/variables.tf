variable "project_name" {
  description = "Nome del progetto"
  type        = string
}

variable "environment" {
  description = "Nome dell'ambiente"
  type        = string
}

# Cognito
variable "user_pool_id" {
  description = "ID del Cognito User Pool"
  type        = string
}

variable "user_pool_arn" {
  description = "ARN del Cognito User Pool"
  type        = string
}

# DynamoDB Tables
variable "courses_table_name" {
  description = "Nome della tabella DynamoDB Courses"
  type        = string
}

variable "courses_table_arn" {
  description = "ARN della tabella DynamoDB Courses"
  type        = string
}

variable "enrollments_table_name" {
  description = "Nome della tabella DynamoDB Enrollments"
  type        = string
}

variable "enrollments_table_arn" {
  description = "ARN della tabella DynamoDB Enrollments"
  type        = string
}

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

variable "results_table_name" {
  description = "Nome della tabella DynamoDB Results"
  type        = string
}

variable "results_table_arn" {
  description = "ARN della tabella DynamoDB Results"
  type        = string
}

# S3 Buckets
variable "documents_bucket_name" {
  description = "Nome del bucket S3 per i documenti"
  type        = string
}

variable "documents_bucket_arn" {
  description = "ARN del bucket S3 per i documenti"
  type        = string
}

# SNS Topic (opzionale per ora)
variable "enrollment_notification_topic_arn" {
  description = "ARN del topic SNS per notifiche enrollment"
  type        = string
  default     = ""
}