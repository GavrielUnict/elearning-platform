# Con GitHub e CodeStar Connection, i trigger sono automatici
# Non servono EventBridge rules

# Mantengo solo le notifiche per pipeline failures
resource "aws_cloudwatch_event_rule" "pipeline_failure" {
  name        = "${var.project_name}-${var.environment}-pipeline-failure"
  description = "Notify on pipeline failures"
  
  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      state = ["FAILED"]
      pipeline = [
        aws_codepipeline.frontend.name,
        aws_codepipeline.ecs.name
        # aws_codepipeline.infrastructure.name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "pipeline_failure_sns" {
  rule      = aws_cloudwatch_event_rule.pipeline_failure.name
  target_id = "SNS"
  arn       = aws_sns_topic.pipeline_notifications.arn
}