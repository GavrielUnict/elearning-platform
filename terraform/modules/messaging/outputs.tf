output "document_processing_queue_arn" {
  description = "ARN della coda SQS per processamento documenti"
  value       = aws_sqs_queue.document_processing.arn
}

output "document_processing_queue_url" {
  description = "URL della coda SQS per processamento documenti"
  value       = aws_sqs_queue.document_processing.url
}

output "enrollment_notifications_topic_arn" {
  description = "ARN del topic SNS per notifiche enrollment"
  value       = aws_sns_topic.enrollment_notifications.arn
}

output "document_processing_notifications_topic_arn" {
  description = "ARN del topic SNS per notifiche documenti"
  value       = aws_sns_topic.document_processing_notifications.arn
}