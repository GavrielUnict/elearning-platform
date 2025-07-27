# SQS Queue per processamento documenti
resource "aws_sqs_queue" "document_processing" {
  name                       = "${var.project_name}-${var.environment}-document-processing"
  delay_seconds              = 0
  max_message_size           = 262144  # 256 KB
  message_retention_seconds  = 345600  # 4 giorni
  receive_wait_time_seconds  = 20      # Long polling
  visibility_timeout_seconds = 900     # 15 minuti per processing
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.document_processing_dlq.arn
    maxReceiveCount     = 3
  })
  
  tags = {
    Name = "${var.project_name}-${var.environment}-document-processing"
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "document_processing_dlq" {
  name                      = "${var.project_name}-${var.environment}-document-processing-dlq"
  message_retention_seconds = 1209600  # 14 giorni
  
  tags = {
    Name = "${var.project_name}-${var.environment}-document-processing-dlq"
  }
}

# SNS Topic per notifiche enrollment
resource "aws_sns_topic" "enrollment_notifications" {
  name = "${var.project_name}-${var.environment}-enrollment-notifications"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-enrollment-notifications"
  }
}

# SNS Topic per notifiche processamento documenti
resource "aws_sns_topic" "document_processing_notifications" {
  name = "${var.project_name}-${var.environment}-document-notifications"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-document-notifications"
  }
}

# Subscription per admin email (se configurata)
resource "aws_sns_topic_subscription" "admin_enrollment_email" {
  count     = var.admin_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.enrollment_notifications.arn
  protocol  = "email"
  endpoint  = var.admin_email
}