variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nome dell'ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nome del progetto"
  type        = string
  default     = "elearning"
}

variable "vpc_cidr" {
  description = "CIDR block per il VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks per le subnet pubbliche"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks per le subnet private"
  type        = list(string)
  default     = ["10.0.10.0/24"]
}

variable "availability_zones" {
  description = "Availability zones da utilizzare"
  type        = list(string)
  default     = ["us-east-1a"]
}

variable "admin_email" {
  description = "Email dell'amministratore per notifiche"
  type        = string
  default     = ""  # Da configurare in terraform.tfvars
}

variable "github_repository" {
  description = "Repository GitHub nel formato owner/repository"
  type        = string
}

variable "github_branch" {
  description = "Branch GitHub da monitorare per CI/CD"
  type        = string
  default     = "main"
}

# Non più necessario
# variable "domain_name" {
#   description = "Nome dominio per l'applicazione (usato per CORS e callback URLs)"
#   type        = string
#   default     = "localhost:3000"  # Da aggiornare con il dominio reale in produzione
# }

# # Rimosso non più necessario
# # Rimossa la vecchia variabile domain_name e aggiunta:
# locals {
#   # Pattern: app-name-env.region.elasticbeanstalk.com
#   eb_domain = "${var.project_name}-${var.environment}-env.${var.aws_region}.elasticbeanstalk.com"
# }