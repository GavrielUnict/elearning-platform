variable "project_name" {
  description = "Nome del progetto"
  type        = string
}

variable "environment" {
  description = "Nome dell'ambiente"
  type        = string
}

variable "admin_email" {
  description = "Email amministratore per notifiche"
  type        = string
  default     = ""
}