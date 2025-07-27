# S3 Event Notifications - created after all modules
resource "aws_s3_bucket_notification" "documents_upload" {
  bucket = module.storage.documents_bucket_name
  
  queue {
    queue_arn     = module.messaging.document_processing_queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "courses/"
    filter_suffix = ".pdf"
  }
  
  depends_on = [
    module.storage,
    module.messaging,
    aws_sqs_queue_policy.allow_s3
  ]
}

# SQS Queue Policy to allow S3 to send messages
resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = module.messaging.document_processing_queue_url
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = module.messaging.document_processing_queue_arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = module.storage.documents_bucket_arn
          }
        }
      }
    ]
  })
  
  depends_on = [module.messaging]
}