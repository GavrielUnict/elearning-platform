# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "frontend" {
  name        = "${var.project_name}-${var.environment}-frontend"
  description = "E-Learning Platform Frontend"
}

# Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "frontend" {
  name                = "${var.project_name}-${var.environment}-frontend-env"
  application         = aws_elastic_beanstalk_application.frontend.name
  solution_stack_name = "64bit Amazon Linux 2 v4.2.0 running Docker"
  tier                = "WebServer"
  
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }
  
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.public_subnet_ids)
  }
  
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", var.public_subnet_ids)
  }
  
  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = "t3.medium"
  }
  
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }
  
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "2"
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "classic"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.elastic_beanstalk_ec2.name
  }
  
  # Serviva solo per ALB, adesso sto usando un Classic Load Balancer (ELB)
  # setting {
  #   namespace = "aws:elbv2:loadbalancer"
  #   name      = "SecurityGroups"
  #   value     = var.alb_security_group_id
  # }

  # Setting per elb (per Classic)
  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "SecurityGroups"
    value     = var.alb_security_group_id
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_AWS_REGION"
    value     = data.aws_region.current.name
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_USER_POOL_ID"
    value     = var.user_pool_id
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_USER_POOL_CLIENT_ID"
    value     = var.user_pool_client_id
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_API_ENDPOINT"
    value     = var.api_gateway_url
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-env"
  }
}

# IAM Role for Elastic Beanstalk
resource "aws_iam_role" "elastic_beanstalk_ec2" {
  name = "${var.project_name}-${var.environment}-eb-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "elastic_beanstalk_web_tier" {
  role       = aws_iam_role.elastic_beanstalk_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "elastic_beanstalk_multicontainer_docker" {
  role       = aws_iam_role.elastic_beanstalk_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_instance_profile" "elastic_beanstalk_ec2" {
  name = "${var.project_name}-${var.environment}-eb-ec2-profile"
  role = aws_iam_role.elastic_beanstalk_ec2.name
}

# Data source
data "aws_region" "current" {}