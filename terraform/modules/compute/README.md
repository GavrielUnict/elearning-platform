# Compute Module - Lambda Functions e API Gateway

## Struttura

```
compute/
├── lambda_layer.tf         # Lambda Layer condiviso
├── lambda_courses.tf       # Functions per gestione corsi
├── lambda_enrollments.tf   # Functions per gestione iscrizioni
├── lambda_documents.tf     # Functions per documenti e quiz
├── api_gateway.tf         # API Gateway REST configuration
├── variables.tf
├── outputs.tf
├── layers/
│   └── shared/
│       └── nodejs/
│           └── utils.js   # Utility functions condivise
└── functions/
    ├── create-course/
    │   └── index.js
    ├── list-courses/
    │   └── index.js
    ├── manage-course/
    │   └── index.js
    └── ... (altre functions)
```

## Lambda Functions

### 1. Course Management
- **create-course**: Crea un nuovo corso (solo docenti)
- **list-courses**: Lista corsi (filtrati per ruolo)
- **manage-course**: GET/PUT/DELETE per singolo corso

### 2. Enrollment Management
- **request-enrollment**: Richiesta iscrizione (studenti)
- **approve-enrollment**: Approva/rifiuta iscrizione (docenti)
- **list-enrollments**: Lista iscrizioni per corso

### 3. Document Management
- **get-presigned-url**: Genera URL per upload/download
- **list-documents**: Lista documenti del corso
- **manage-document**: Gestisce singolo documento

### 4. Quiz Management
- **get-quiz**: Recupera quiz per documento
- **submit-quiz-results**: Invia risultati quiz

### 5. Results
- **list-results**: Lista risultati quiz dello studente

## API Endpoints

Tutti gli endpoint richiedono autenticazione tramite Cognito token nell'header:
```
Authorization: Bearer <cognito-id-token>
```

### Courses
- `GET /courses` - Lista corsi
- `POST /courses` - Crea corso
- `GET /courses/{courseId}` - Dettagli corso
- `PUT /courses/{courseId}` - Aggiorna corso
- `DELETE /courses/{courseId}` - Elimina corso

### Enrollments
- `GET /courses/{courseId}/enrollments` - Lista iscrizioni
- `POST /courses/{courseId}/enrollments` - Richiedi iscrizione
- `PUT /courses/{courseId}/enrollments/{enrollmentId}` - Approva/rifiuta

### Documents
- `GET /courses/{courseId}/documents` - Lista documenti
- `POST /courses/{courseId}/documents` - Ottieni upload URL
- `GET /courses/{courseId}/documents/{documentId}` - Download URL
- `DELETE /courses/{courseId}/documents/{documentId}` - Elimina documento

### Quiz
- `GET /courses/{courseId}/documents/{documentId}/quiz` - Ottieni quiz
- `POST /courses/{courseId}/documents/{documentId}/quiz` - Invia risultati

### Results
- `GET /results` - Lista risultati studente

## Preparazione Functions

Prima del deployment, esegui:
```bash
cd terraform/modules/compute
chmod +x prepare-lambda-functions.sh
./prepare-lambda-functions.sh
```

## Test con cURL

Esempio di test (sostituisci con i tuoi valori):
```bash
# Ottieni token da Cognito (implementa autenticazione)
TOKEN="your-cognito-id-token"
API_URL="https://your-api-id.execute-api.us-east-1.amazonaws.com/dev"

# Lista corsi
curl -H "Authorization: Bearer $TOKEN" \
     "$API_URL/courses"

# Crea corso (solo docenti)
curl -X POST \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name":"Matematica 101","description":"Corso base di matematica"}' \
     "$API_URL/courses"
```

## Note Implementative

1. **Autorizzazione**: 
   - I gruppi Cognito determinano i permessi (Docenti/Studenti)
   - Ownership check per update/delete

2. **Error Handling**:
   - 400: Bad Request (parametri mancanti)
   - 403: Forbidden (permessi insufficienti)
   - 404: Not Found
   - 500: Internal Server Error

3. **Performance**:
   - Lambda Layer riduce cold start
   - DynamoDB on-demand scaling
   - API Gateway caching (opzionale)

## Costi Stimati (Free Tier)

- Lambda: 1M richieste/mese gratuite
- API Gateway: 1M chiamate/mese gratuite (primo anno)
- CloudWatch Logs: 5GB gratuite