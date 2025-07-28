# GitHub Connection tramite CodeStar
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-${var.environment}-github-connection"
  provider_type = "GitHub"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-github-connection"
  }
}

# S3 Bucket for CodePipeline artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.project_name}-${var.environment}-pipeline-artifacts-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-pipeline-artifacts"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# SNS Topic for pipeline notifications
resource "aws_sns_topic" "pipeline_notifications" {
  name = "${var.project_name}-${var.environment}-pipeline-notifications"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-pipeline-notifications"
  }
}

resource "aws_sns_topic_subscription" "pipeline_email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "codebuild_frontend" {
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-frontend-build"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "codebuild_ecs" {
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-ecs-build"
  retention_in_days = 7
}

# resource "aws_cloudwatch_log_group" "codebuild_terraform" {
#   name              = "/aws/codebuild/${var.project_name}-${var.environment}-terraform-build"
#   retention_in_days = 7
# }