# Cognito Lambda Triggers Setup

## Preparazione delle Lambda Functions

Prima di applicare il modulo Cognito, è necessario creare i file ZIP delle Lambda functions.

### Struttura richiesta:
```
lambda-functions/
├── post-confirmation/
│   └── index.js
├── pre-authentication/
│   └── index.js
├── post-confirmation.zip
└── pre-authentication.zip
```

### Passaggi:

1. **Crea le directory**:
   ```bash
   cd terraform/modules/cognito
   mkdir -p lambda-functions/post-confirmation
   mkdir -p lambda-functions/pre-authentication
   ```

2. **Copia i file JavaScript** dalle rispettive directory

3. **Crea i file ZIP**:
   ```bash
   cd lambda-functions/post-confirmation
   zip ../post-confirmation.zip index.js
   cd ../pre-authentication
   zip ../pre-authentication.zip index.js
   cd ../..
   ```

   O usa lo script fornito:
   ```bash
   chmod +x prepare-lambda.sh
   ./prepare-lambda.sh
   ```

## Funzionalità delle Lambda

### Post Confirmation
- Assegna automaticamente l'utente al gruppo appropriato (Docenti o Studenti)
- Basato sull'attributo custom `role` fornito durante la registrazione
- Default: assegna al gruppo "Studenti" se il ruolo non è specificato

### Pre Authentication
- Registra tutti i tentativi di autenticazione in CloudWatch Logs
- Traccia IP sorgente, device key, timestamp
- Utile per audit e sicurezza