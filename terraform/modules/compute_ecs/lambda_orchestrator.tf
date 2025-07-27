# Lambda Orchestrator per triggerare ECS tasks
resource "aws_lambda_function" "ecs_orchestrator" {
  filename         = "${path.module}/functions/ecs-orchestrator.zip"
  function_name    = "${var.project_name}-${var.environment}-ecs-orchestrator"
  role            = aws_iam_role.lambda_orchestrator_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 300
  memory_size     = 256
  
  environment {
    variables = {
      ECS_CLUSTER_NAME     = aws_ecs_cluster.main.name
      TASK_DEFINITION_ARN  = aws_ecs_task_definition.quiz_processor.arn
      SUBNET_IDS           = join(",", var.private_subnet_ids)
      SECURITY_GROUP_ID    = var.ecs_security_group_id
      ASG_NAME            = aws_autoscaling_group.ecs_instances.name
    }
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-orchestrator"
  }
}

# IAM Role for Lambda Orchestrator
resource "aws_iam_role" "lambda_orchestrator_role" {
  name = "${var.project_name}-${var.environment}-lambda-orchestrator-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda Orchestrator
resource "aws_iam_role_policy" "lambda_orchestrator_policy" {
  name = "${var.project_name}-${var.environment}-lambda-orchestrator-policy"
  role = aws_iam_role.lambda_orchestrator_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_role.arn,
          aws_iam_role.ecs_execution_role.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.document_processing_queue_arn
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_orchestrator" {
  name              = "/aws/lambda/${aws_lambda_function.ecs_orchestrator.function_name}"
  retention_in_days = 7
}

# Event Source Mapping for SQS
resource "aws_lambda_event_source_mapping" "sqs_to_orchestrator" {
  event_source_arn = var.document_processing_queue_arn
  function_name    = aws_lambda_function.ecs_orchestrator.arn
  batch_size       = 1
}

# Lambda permission for SQS
resource "aws_lambda_permission" "sqs_invoke" {
  statement_id  = "AllowSQSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_orchestrator.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = var.document_processing_queue_arn
}