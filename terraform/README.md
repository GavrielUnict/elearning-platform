# E-Learning Platform - Infrastructure as Code

## Prerequisiti

1. AWS CLI configurato con credenziali appropriate
2. Terraform >= 1.0

## Struttura del Progetto

```
terraform/
├── main.tf              # Configurazione principale
├── variables.tf         # Variabili globali
├── outputs.tf           # Output principali
├── terraform.tfvars     # Valori delle variabili (non committare!)
├── example.tfvars       # Esempio di configurazione
└── modules/             # Moduli riutilizzabili
    ├── networking/      # VPC, Subnet, Security Groups
    ├── cognito/         # Autenticazione utenti
    ├── storage/         # S3, DynamoDB
    ├── compute/         # Lambda, ECS, Elastic Beanstalk
    ├── messaging/       # SQS, SNS
    └── cicd/           # CodeCommit, CodePipeline
```

## Setup Iniziale

1. **Copia e configura le variabili:**
   ```bash
   cp example.tfvars terraform.tfvars
   # Modifica terraform.tfvars con i tuoi valori
   ```

2. **Inizializza Terraform:**
   ```bash
   terraform init
   ```

## Deployment

### Prima volta
```bash
# Verifica il piano
terraform plan

# Applica le modifiche
terraform apply
```

### Aggiornamenti
```bash
# Sempre verificare prima
terraform plan

# Poi applicare
terraform apply
```

### Distruzione risorse
```bash
# ATTENZIONE: Questo eliminerà TUTTE le risorse!
terraform destroy
```

## Moduli

### Networking
- VPC con subnet pubbliche e private
- NAT Gateway per accesso internet dalle subnet private (1 sola AZ per ridurre costi)
- Security Groups per ogni servizio
- VPC Endpoints per S3 e DynamoDB (risparmio costi)

### Altri moduli (da implementare)
- Cognito: User pools per docenti/studenti
- Storage: S3 buckets e tabelle DynamoDB
- Compute: Lambda functions, ECS cluster, Elastic Beanstalk
- Messaging: Code SQS e topic SNS
- CI/CD: Pipeline automatizzate

## Best Practices

1. **Non committare mai `terraform.tfvars`** - contiene informazioni sensibili
2. **Usa sempre `terraform plan`** prima di applicare modifiche
3. **Tagga tutte le risorse** per tracking dei costi
4. **Monitora il Free Tier** tramite AWS Budgets
5. **Fai backup del terraform.tfstate** regolarmente (è salvato solo localmente)

## Troubleshooting

### Errore di inizializzazione
```bash
# Pulisci la cache e reinizializza
rm -rf .terraform/
terraform init
```

### State corrotto
Poiché lo state è locale, assicurati di:
- Fare backup regolari di `terraform.tfstate` e `terraform.tfstate.backup`
- Non modificare mai manualmente questi file

## Costi Stimati (Free Tier)

- VPC: Gratuito
- NAT Gateway: ~$0.045/ora (circa $32/mese con 1 AZ)
- EC2 (per ECS): t3.micro eligible per free tier
- Lambda: 1M richieste/mese gratuite
- DynamoDB: 25GB storage gratuito
- S3: 5GB storage gratuito

**Nota**: Il NAT Gateway è il costo principale. Per azzerare i costi durante lo sviluppo,
puoi distruggere l'infrastruttura quando non la usi:
```bash
terraform destroy  # fine giornata
terraform apply    # inizio lavoro
```