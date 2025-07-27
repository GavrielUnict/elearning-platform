variable "project_name" {
  description = "Nome del progetto"
  type        = string
}

variable "environment" {
  description = "Nome dell'ambiente"
  type        = string
}

# Rimosso non più necessario
# variable "domain_name" {
#   description = "Nome dominio per CORS"
#   type        = string
#   default     = "localhost:3000"
# }