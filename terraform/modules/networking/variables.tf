variable "project_name" {
  description = "Nome del progetto"
  type        = string
}

variable "environment" {
  description = "Nome dell'ambiente"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block per il VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks per le subnet pubbliche"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks per le subnet private"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones da utilizzare"
  type        = list(string)
}