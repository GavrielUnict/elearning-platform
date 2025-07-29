# Guida Completa CI/CD - E-Learning Platform

## 📋 Panoramica

La Fase 7 implementa un sistema CI/CD completo utilizzando AWS CodeCommit, CodeBuild e CodePipeline. Il sistema gestisce automaticamente build e deployment per:

- **Frontend React** → Elastic Beanstalk
- **Container ECS** → ECR e ECS Task
- **Infrastruttura** → Terraform con approvazione manuale

## 🏗️ Architettura CI/CD

### Repository Structure (Monorepo)
```
elearning-platform/              # Un solo repository CodeCommit
├── terraform/                   # Infrastructure as Code
├── src/
│   ├── frontend/               # React app
│   ├── lambda/                 # Lambda functions (gestite da Terraform)
│   └── ecs-container/          # Processing container
└── buildspec/                  # Build specifications
    ├── frontend-buildspec.yml
    ├── ecs-buildspec.yml
    ├── terraform-plan-buildspec.yml
    └── terraform-apply-buildspec.yml
```

### Pipeline Architecture
1. **Frontend Pipeline**: Automatica su push
   - Source → Build → Deploy to Elastic Beanstalk
   
2. **ECS Pipeline**: Automatica su push
   - Source → Build → Push to ECR → Update ECS Task
   
3. **Infrastructure Pipeline**: Con approvazione manuale
   - Source → Plan → Manual Approval → Apply

## 📦 Implementazione Step-by-Step

### Step 1: Aggiorna main.tf

Aggiungi il modulo CI/CD al tuo `terraform/main.tf`:

```hcl
# CI/CD module
module "cicd" {
  source = "./modules/cicd"
  
  project_name       = var.project_name
  environment        = var.environment
  notification_email = var.admin_email
  
  # Frontend variables
  user_pool_id        = module.cognito.user_pool_id
  user_pool_client_id = module.cognito.web_client_id
  api_gateway_url     = module.compute.api_gateway_invoke_url
  
  elastic_beanstalk_app_name = module.elastic_beanstalk.application_name
  elastic_beanstalk_env_name = module.elastic_beanstalk.environment_name
  
  # ECS variables
  ecr_repository_name = "${var.project_name}-${var.environment}-quiz-processor"
  ecs_cluster_name    = module.compute_ecs.ecs_cluster_name
  
  depends_on = [
    module.elastic_beanstalk,
    module.compute_ecs
  ]
}
```

### Step 2: Crea la directory buildspec

```bash
mkdir -p buildspec
```

I file buildspec sono già stati creati tramite gli artifacts.

### Step 3: Applica Terraform

```bash
cd terraform
terraform init
terraform apply
```

### Step 4: Configura Git Credentials per CodeCommit

```bash
# Configura credential helper
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
```

### Step 5: Inizializza e Push al Repository

```bash
# Dalla root del progetto
git init
git add .
git commit -m "Initial commit with CI/CD"

# Aggiungi CodeCommit come remote (usa l'URL dal terraform output)
REPO_URL=$(cd terraform && terraform output -json cicd_details | jq -r '.codecommit_http_url')
git remote add codecommit $REPO_URL

# Push al repository
git push codecommit main
```

### Step 6: Usa lo Script Automatico (Alternativa)

Ho creato uno script che automatizza tutto:

```bash
chmod +x setup-cicd.sh
./setup-cicd.sh
```

## 🔧 Configurazione e Personalizzazione

### Environment Variables in CodeBuild

Le variabili d'ambiente sono già configurate nei progetti CodeBuild:

- **Frontend Build**: Riceve automaticamente Cognito IDs e API URL
- **ECS Build**: Riceve ECR repository e AWS account info
- **Terraform Build**: Riceve project name e environment

### Trigger Automatici

Le pipeline si attivano automaticamente quando:
- Push su branch `main` in CodeCommit
- I trigger sono gestiti da EventBridge Rules

### Notifiche

- **Pipeline Failures**: Email automatiche all'admin
- **Infrastructure Changes**: Richiesta approvazione manuale
- **Build Logs**: Disponibili in CloudWatch Logs

## 📊 Monitoraggio

### AWS Console Links

Dopo il deploy, puoi monitorare le pipeline:

1. **CodePipeline Console**: 
   ```
   https://console.aws.amazon.com/codesuite/codepipeline/pipelines
   ```

2. **CodeBuild Projects**:
   ```
   https://console.aws.amazon.com/codesuite/codebuild/projects
   ```

3. **CodeCommit Repository**:
   ```
   https://console.aws.amazon.com/codesuite/codecommit/repositories
   ```

### CloudWatch Logs

Ogni build genera logs in:
- `/aws/codebuild/elearning-dev-frontend-build`
- `/aws/codebuild/elearning-dev-ecs-build`
- `/aws/codebuild/elearning-dev-terraform-build`

## 🚀 Workflow di Sviluppo

### 1. Modifiche al Frontend
```bash
# Fai le tue modifiche in src/frontend
git add src/frontend/
git commit -m "feat: add new feature to frontend"
git push codecommit main

# La pipeline frontend si attiva automaticamente
```

### 2. Modifiche al Container ECS
```bash
# Modifica src/ecs-container
git add src/ecs-container/
git commit -m "fix: improve quiz generation"
git push codecommit main

# La pipeline ECS builda e deploya automaticamente
```

### 3. Modifiche all'Infrastruttura
```bash
# Modifica terraform/
git add terraform/
git commit -m "infra: add new DynamoDB table"
git push codecommit main

# La pipeline richiederà approvazione manuale dopo il plan
```

## 🛠️ Troubleshooting

### Pipeline Failed
1. Controlla i log in CodeBuild
2. Verifica le IAM permissions
3. Controlla che tutti i segreti siano configurati

### Git Push Issues
```bash
# Reset credentials
git config --global --unset credential.helper
git config --global credential.helper '!aws codecommit credential-helper $@'
```

### Build Failures

**Frontend Build Failed**:
- Verifica `package.json` dependencies
- Controlla che le env variables siano corrette

**ECS Build Failed**:
- Verifica Docker login to ECR
- Controlla il Dockerfile syntax

**Terraform Failed**:
- Verifica terraform.tfvars
- Controlla AWS permissions

## 💰 Costi

Il CI/CD aggiunge questi costi (mostly Free Tier):

- **CodeCommit**: Free fino a 5 utenti
- **CodeBuild**: 100 minuti/mese gratuiti
- **CodePipeline**: 1 pipeline gratuita
- **S3 (artifacts)**: Minimo, dentro Free Tier

## 🔐 Best Practices

1. **Branch Protection**: Usa solo `main` per production
2. **Code Review**: Implementa PR workflow (future)
3. **Secrets**: Usa AWS Secrets Manager, mai hardcode
4. **Testing**: Aggiungi unit tests nelle build
5. **Rollback**: CodeDeploy supporta rollback automatico

## 📝 Next Steps

1. **Aggiungi Tests**:
   ```yaml
   # In buildspec files
   - npm test -- --coverage --watchAll=false
   ```

2. **Multi-Environment**:
   - Crea branch `dev`, `staging`, `prod`
   - Pipeline diverse per ambiente

3. **Monitoring Avanzato**:
   - CloudWatch Dashboards
   - X-Ray tracing
   - Cost alerts

## 🎉 Conclusione

Il tuo CI/CD è ora completamente operativo! Ogni push su `main` attiverà automaticamente le pipeline appropriate. Ricorda di:

- Monitorare le email per notifiche
- Approvare manualmente i cambi infrastrutturali
- Controllare i costi regolarmente

Happy deploying! 🚀 