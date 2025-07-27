# CI/CD Module

Questo modulo Terraform crea l'infrastruttura CI/CD completa per l'E-Learning Platform.

## Risorse Create

### CodeCommit
- **Repository**: Monorepo per tutto il codice del progetto

### CodeBuild Projects
1. **Frontend Build**: Compila React e crea package per Elastic Beanstalk
2. **ECS Build**: Build Docker image e push a ECR
3. **Terraform Plan**: Pianifica modifiche infrastrutturali
4. **Terraform Apply**: Applica modifiche approvate

### CodePipeline
1. **Frontend Pipeline**: Deploy automatico a Elastic Beanstalk
2. **ECS Pipeline**: Deploy automatico container a ECS
3. **Infrastructure Pipeline**: Deploy Terraform con approvazione

### Supporting Resources
- S3 Bucket per pipeline artifacts
- SNS Topic per notifiche
- EventBridge Rules per trigger automatici
- IAM Roles e Policies
- CloudWatch Log Groups

## Variabili

| Nome | Descrizione | Tipo | Default |
|------|-------------|------|---------|
| project_name | Nome del progetto | string | - |
| environment | Ambiente (dev/staging/prod) | string | - |
| notification_email | Email per notifiche pipeline | string | "" |
| user_pool_id | Cognito User Pool ID | string | - |
| user_pool_client_id | Cognito Client ID | string | - |
| api_gateway_url | API Gateway URL | string | - |
| elastic_beanstalk_app_name | Nome app EB | string | - |
| elastic_beanstalk_env_name | Nome environment EB | string | - |
| ecr_repository_name | Nome repo ECR | string | - |
| ecs_cluster_name | Nome cluster ECS | string | - |

## Output

| Nome | Descrizione |
|------|-------------|
| codecommit_repository_clone_url_http | HTTP URL per clonare il repo |
| codecommit_repository_clone_url_ssh | SSH URL per clonare il repo |
| frontend_pipeline_name | Nome della pipeline frontend |
| ecs_pipeline_name | Nome della pipeline ECS |
| infrastructure_pipeline_name | Nome della pipeline infrastructure |
| pipeline_artifacts_bucket | Bucket S3 per artifacts |
| pipeline_notifications_topic_arn | ARN topic SNS notifiche |

## Utilizzo

```hcl
module "cicd" {
  source = "./modules/cicd"
  
  project_name       = var.project_name
  environment        = var.environment
  notification_email = var.admin_email
  
  # Frontend configuration
  user_pool_id        = module.cognito.user_pool_id
  user_pool_client_id = module.cognito.web_client_id
  api_gateway_url     = module.compute.api_gateway_invoke_url
  
  elastic_beanstalk_app_name = module.elastic_beanstalk.application_name
  elastic_beanstalk_env_name = module.elastic_beanstalk.environment_name
  
  # ECS configuration
  ecr_repository_name = "${var.project_name}-${var.environment}-quiz-processor"
  ecs_cluster_name    = module.compute_ecs.ecs_cluster_name
}
```

## Pipeline Triggers

Le pipeline sono triggerate automaticamente da:
- Push su branch `main` in CodeCommit
- Gestito tramite EventBridge Rules

## Buildspec Files

I file buildspec devono essere nella directory `/buildspec` del repository:
- `frontend-buildspec.yml`
- `ecs-buildspec.yml`
- `terraform-plan-buildspec.yml`
- `terraform-apply-buildspec.yml`

## Costi Stimati

- CodeCommit: Gratuito per primi 5 utenti
- CodeBuild: 100 minuti/mese gratuiti
- CodePipeline: 1 pipeline gratuita
- S3/CloudWatch: Dentro Free Tier per uso normale