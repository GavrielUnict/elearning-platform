output "vpc_id" {
  description = "ID del VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block del VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs delle subnet pubbliche"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs delle subnet private"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "alb_security_group_id" {
  description = "ID del security group ALB"
  value       = aws_security_group.alb.id
}

output "elastic_beanstalk_security_group_id" {
  description = "ID del security group Elastic Beanstalk"
  value       = aws_security_group.elastic_beanstalk.id
}

output "ecs_security_group_id" {
  description = "ID del security group ECS"
  value       = aws_security_group.ecs.id
}

output "lambda_security_group_id" {
  description = "ID del security group Lambda"
  value       = aws_security_group.lambda.id
}

output "rds_security_group_id" {
  description = "ID del security group RDS"
  value       = aws_security_group.rds.id
}

output "s3_vpc_endpoint_id" {
  description = "ID del VPC endpoint S3"
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_vpc_endpoint_id" {
  description = "ID del VPC endpoint DynamoDB"
  value       = aws_vpc_endpoint.dynamodb.id
}