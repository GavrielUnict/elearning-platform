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

variable "public_subnet_ids" {
  description = "IDs delle subnet pubbliche"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID del security group per ALB"
  type        = string
}

variable "user_pool_id" {
  description = "ID del Cognito User Pool"
  type        = string
}

variable "user_pool_client_id" {
  description = "ID del Cognito User Pool Client"
  type        = string
}

variable "api_gateway_url" {
  description = "URL dell'API Gateway"
  type        = string
}