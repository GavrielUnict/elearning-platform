output "environment_url" {
  description = "URL dell'ambiente Elastic Beanstalk"
  value       = aws_elastic_beanstalk_environment.frontend.endpoint_url
}

output "environment_name" {
  description = "Nome dell'ambiente Elastic Beanstalk"
  value       = aws_elastic_beanstalk_environment.frontend.name
}

output "application_name" {
  description = "Nome dell'applicazione Elastic Beanstalk"
  value       = aws_elastic_beanstalk_application.frontend.name
}

output "environment_cname" {
  description = "CNAME dell'ambiente Elastic Beanstalk"
  value       = aws_elastic_beanstalk_environment.frontend.cname
}