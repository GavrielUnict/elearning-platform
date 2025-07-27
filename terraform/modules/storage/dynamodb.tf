# Tabella Courses
resource "aws_dynamodb_table" "courses" {
  name         = "${var.project_name}-${var.environment}-courses"
  billing_mode = "PAY_PER_REQUEST"  # On-demand per Free Tier
  hash_key     = "courseId"
  
  attribute {
    name = "courseId"
    type = "S"
  }
  
  attribute {
    name = "teacherId"
    type = "S"
  }
  
  # GSI per query by teacher
  global_secondary_index {
    name            = "teacherId-index"
    hash_key        = "teacherId"
    projection_type = "ALL"
  }
  
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }
  
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-courses"
  }
}

# Tabella Enrollments
resource "aws_dynamodb_table" "enrollments" {
  name         = "${var.project_name}-${var.environment}-enrollments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "studentId"
  range_key    = "courseId"
  
  attribute {
    name = "studentId"
    type = "S"
  }
  
  attribute {
    name = "courseId"
    type = "S"
  }
  
  # GSI per query by course
  global_secondary_index {
    name            = "courseId-studentId-index"
    hash_key        = "courseId"
    range_key       = "studentId"
    projection_type = "ALL"
  }
  
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-enrollments"
  }
}

# Tabella Documents
resource "aws_dynamodb_table" "documents" {
  name         = "${var.project_name}-${var.environment}-documents"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "courseId"
  range_key    = "documentId"
  
  attribute {
    name = "courseId"
    type = "S"
  }
  
  attribute {
    name = "documentId"
    type = "S"
  }
  
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-documents"
  }
}

# Tabella Quizzes
resource "aws_dynamodb_table" "quizzes" {
  name         = "${var.project_name}-${var.environment}-quizzes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "documentId"
  range_key    = "quizId"
  
  attribute {
    name = "documentId"
    type = "S"
  }
  
  attribute {
    name = "quizId"
    type = "S"
  }
  
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-quizzes"
  }
}

# Tabella Results
resource "aws_dynamodb_table" "results" {
  name         = "${var.project_name}-${var.environment}-results"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "studentId"
  range_key    = "quizIdTimestamp"  # Formato: quizId#timestamp
  
  attribute {
    name = "studentId"
    type = "S"
  }
  
  attribute {
    name = "quizIdTimestamp"
    type = "S"
  }
  
  attribute {
    name = "quizId"
    type = "S"
  }
  
  # GSI per query by quiz
  global_secondary_index {
    name            = "quizId-index"
    hash_key        = "quizId"
    projection_type = "ALL"
  }
  
  server_side_encryption {
    enabled = true
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-results"
  }
}