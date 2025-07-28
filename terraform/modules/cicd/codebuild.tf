# CodeBuild Project - Frontend
resource "aws_codebuild_project" "frontend" {
  name         = "${var.project_name}-${var.environment}-frontend-build"
  description  = "Build React frontend application"
  service_role = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    
    environment_variable {
      name  = "REACT_APP_AWS_REGION"
      value = data.aws_region.current.name
    }
    
    environment_variable {
      name  = "REACT_APP_USER_POOL_ID"
      value = var.user_pool_id
    }
    
    environment_variable {
      name  = "REACT_APP_USER_POOL_CLIENT_ID"
      value = var.user_pool_client_id
    }
    
    environment_variable {
      name  = "REACT_APP_API_ENDPOINT"
      value = var.api_gateway_url
    }
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/frontend-buildspec.yml"
  }
  
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild_frontend.name
    }
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-build"
  }
}

# CodeBuild Project - ECS Container
resource "aws_codebuild_project" "ecs" {
  name         = "${var.project_name}-${var.environment}-ecs-build"
  description  = "Build and push ECS container"
  service_role = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true  # Required for Docker
    
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    
    environment_variable {
      name  = "ECR_REPOSITORY_NAME"
      value = var.ecr_repository_name
    }
    
    environment_variable {
      name  = "CONTAINER_NAME"
      value = "quiz-processor"
    }
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/ecs-buildspec.yml"
  }
  
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild_ecs.name
    }
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-build"
  }
}

# CodeBuild Project - Terraform Plan
resource "aws_codebuild_project" "terraform_plan" {
  name         = "${var.project_name}-${var.environment}-terraform-plan"
  description  = "Terraform plan for infrastructure changes"
  service_role = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    
    environment_variable {
      name  = "TF_VAR_environment"
      value = var.environment
    }
    
    environment_variable {
      name  = "TF_VAR_project_name"
      value = var.project_name
    }
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/terraform-plan-buildspec.yml"
  }
  
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild_terraform.name
    }
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-plan"
  }
}

# CodeBuild Project - Terraform Apply
# Trova il resource aws_codebuild_project.terraform_apply e sostituiscilo completamente con:
resource "aws_codebuild_project" "terraform_apply" {
  name         = "${var.project_name}-${var.environment}-terraform-apply"
  description  = "Terraform apply for infrastructure changes"
  service_role = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    
    environment_variable {
      name  = "TF_VAR_environment"
      value = var.environment
    }
    
    environment_variable {
      name  = "TF_VAR_project_name"
      value = var.project_name
    }
  }
  
  source {
    type = "CODEPIPELINE"
    buildspec = <<-EOT
    version: 0.2

    phases:
      install:
        commands:
          - echo Installing Terraform...
          - cd /tmp
          - wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
          - unzip -o terraform_1.6.6_linux_amd64.zip
          - mv terraform /usr/local/bin/
          - rm terraform_1.6.6_linux_amd64.zip
          - terraform --version
          
      pre_build:
        commands:
          - echo Extracting plan artifacts...
          - cd $CODEBUILD_SRC_DIR_plan_output
          - ls -la
          - cd terraform
          - terraform init -backend=false
          
      build:
        commands:
          - echo Applying Terraform plan...
          - terraform apply -auto-approve tfplan
          
      post_build:
        commands:
          - echo Terraform apply completed on `date`
          - echo Saving outputs...
          - terraform output -json > outputs.json

    artifacts:
      files:
        - terraform/outputs.json
      name: terraform-apply-$(date +%Y-%m-%d)
    EOT
  }
  
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild_terraform.name
    }
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-apply"
  }
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}