# ECR Repository
resource "aws_ecr_repository" "quiz_processor" {
  name                 = "${var.project_name}-${var.environment}-quiz-processor"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-quiz-processor"
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "quiz_processor" {
  repository = aws_ecr_repository.quiz_processor.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"
  
  setting {
    name  = "containerInsights"
    value = "disabled"  # Free Tier
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# Launch Template per ECS instances
resource "aws_launch_template" "ecs_instances" {
  name_prefix   = "${var.project_name}-${var.environment}-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }
  
  vpc_security_group_ids = [var.ecs_security_group_id]
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
  EOF
  )
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-ecs-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs_instances" {
  name                = "${var.project_name}-${var.environment}-ecs-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 0
  max_size            = 1
  desired_capacity    = 0  # Start with 0 to save costs
  
  launch_template {
    id      = aws_launch_template.ecs_instances.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-ecs-instance"
    propagate_at_launch = true
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "main" {
  name = "${var.project_name}-${var.environment}-capacity-provider"
  
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_instances.arn
    
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }
}

# Associate capacity provider with cluster
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name
  
  capacity_providers = [aws_ecs_capacity_provider.main.name]
  
  default_capacity_provider_strategy {
    base              = 0
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

# Task Definition
resource "aws_ecs_task_definition" "quiz_processor" {
  family                   = "${var.project_name}-${var.environment}-quiz-processor"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "256"    # Ridotto da 512
  memory                   = "512"    # Ridotto da 1024 a 512 MB
  
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  
  container_definitions = jsonencode([
    {
      name  = "quiz-processor"
      image = "${aws_ecr_repository.quiz_processor.repository_url}:latest"
      
      memory = 512    # Ridotto da 1024
      cpu    = 256    # Ridotto da 512
      
      essential = true
      
      environment = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = data.aws_region.current.name
        },
        {
          name  = "DOCUMENTS_BUCKET"
          value = var.documents_bucket_name
        },
        {
          name  = "DOCUMENTS_TABLE"
          value = var.documents_table_name
        },
        {
          name  = "QUIZZES_TABLE"
          value = var.quizzes_table_name
        },
        {
          name  = "OPENAI_API_KEY_SECRET_NAME"
          value = aws_secretsmanager_secret.openai_api_key.name
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_quiz_processor.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
  
  tags = {
    Name = "${var.project_name}-${var.environment}-quiz-processor"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_quiz_processor" {
  name              = "/ecs/${var.project_name}-${var.environment}-quiz-processor"
  retention_in_days = 7
}

# Secrets Manager for OpenAI API Key
resource "aws_secretsmanager_secret" "openai_api_key" {
  name = "${var.project_name}-${var.environment}-openai-api-key"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-openai-api-key"
  }
}

# Note: The actual secret value should be added manually via console or CLI
resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = "PLACEHOLDER-ADD-VIA-CONSOLE"
  
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Data sources
data "aws_region" "current" {}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}