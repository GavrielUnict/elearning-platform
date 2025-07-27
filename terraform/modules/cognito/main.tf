# User Pool Cognito
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-${var.environment}-user-pool"
  
  # Attributi richiesti
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  
  # Schema attributi
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
  
  schema {
    name                     = "name"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
  
  schema {
    name                     = "family_name"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
  
  # Attributo custom per il ruolo
  schema {
    name                     = "role"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
  
  # Policy password
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }
  
  # MFA opzionale
  mfa_configuration = "OPTIONAL"
  
  software_token_mfa_configuration {
    enabled = true
  }
  
  # Configurazione account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  
  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  
  # Lambda triggers
  lambda_config {
    post_confirmation = aws_lambda_function.post_confirmation.arn
    pre_authentication = aws_lambda_function.pre_authentication.arn
  }
  
  # Prevenzione cancellazione accidentale
  deletion_protection = var.environment == "prod" ? "ACTIVE" : "INACTIVE"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-user-pool"
  }
}

# App Client per frontend
resource "aws_cognito_user_pool_client" "web_client" {
  name         = "${var.project_name}-${var.environment}-web-client"
  user_pool_id = aws_cognito_user_pool.main.id
  
  # Token configuration
  access_token_validity  = 1  # 1 ora
  id_token_validity      = 1  # 1 ora
  refresh_token_validity = 30 # 30 giorni
  
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  
  # # COMMENTATO TUTTO IL BLOCCO OAuth - NON SERVE per Auth.signIn()
  # # OAuth configuration
  # allowed_oauth_flows_user_pool_client = true
  # allowed_oauth_flows                  = ["code", "implicit"]
  # allowed_oauth_scopes                 = ["email", "openid", "profile"]
  
  # # Callback URLs (da aggiornare con URL reali) - NON PIU' NECESSARIE
  # callback_urls = [
  #   "http://localhost:3000/callback",
  #   "http://${var.domain_name}/callback",
  #   "https://${var.domain_name}/callback"
  # ]
  
  # logout_urls = [
  #   "http://localhost:3000/logout",
  #   "http://${var.domain_name}/logout",
  #   "https://${var.domain_name}/logout"
  # ]
  
  # Security
  prevent_user_existence_errors = "ENABLED"
  
  # Attributi leggibili/scrivibili
  read_attributes = [
    "email",
    "email_verified",
    "name",
    "family_name",
    "custom:role"
  ]
  
  write_attributes = [
    "email",
    "name",
    "family_name",
    "custom:role"
  ]
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  
  generate_secret = false
}

# Gruppi Cognito
resource "aws_cognito_user_group" "docenti" {
  name         = "Docenti"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Gruppo per i docenti"
  precedence   = 1
}

resource "aws_cognito_user_group" "studenti" {
  name         = "Studenti"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Gruppo per gli studenti"
  precedence   = 2
}

# User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${var.environment}-${random_string.domain_suffix.result}"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "random_string" "domain_suffix" {
  length  = 8
  special = false
  upper   = false
}