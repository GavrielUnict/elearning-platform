#!/bin/bash

echo "=== Test Cognito e API Gateway ==="
echo ""

# Colori
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ottieni i dettagli da Terraform
cd terraform
# USER_POOL_ID=$(terraform output -json cognito_details | jq -r '.user_pool_id')
USER_POOL_ID="us-east-1_lOatq4qLV"
# CLIENT_ID=$(terraform output -json cognito_details | jq -r '.web_client_id')
CLIENT_ID="2sdst94j4324qdmpds4eeevnfg"
# API_URL=$(terraform output -json api_details | jq -r '.api_gateway_url')
API_URL="https://ecp5ni7u4m.execute-api.us-east-1.amazonaws.com/dev"
cd ..

echo -e "${BLUE}Dettagli Cognito:${NC}"
echo "User Pool ID: $USER_POOL_ID"
echo "Client ID: $CLIENT_ID"
echo "API URL: $API_URL"
echo ""

# Funzione per registrare un utente
register_user() {
    local EMAIL=$1
    local PASSWORD=$2
    local NAME=$3
    local SURNAME=$4
    local ROLE=$5
    
    echo -e "${YELLOW}Registrazione utente $EMAIL...${NC}"
    
    aws cognito-idp sign-up \
        --client-id "$CLIENT_ID" \
        --username "$EMAIL" \
        --password "$PASSWORD" \
        --user-attributes \
            Name=email,Value="$EMAIL" \
            Name=name,Value="$NAME" \
            Name=family_name,Value="$SURNAME" \
            Name="custom:role",Value="$ROLE" \
        --region us-east-1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Utente registrato${NC}"
    else
        echo "Errore nella registrazione"
        return 1
    fi
}

# Funzione per confermare un utente (admin)
confirm_user() {
    local EMAIL=$1
    
    echo -e "${YELLOW}Conferma utente $EMAIL...${NC}"
    
    aws cognito-idp admin-confirm-sign-up \
        --user-pool-id "$USER_POOL_ID" \
        --username "$EMAIL" \
        --region us-east-1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Utente confermato${NC}"
    else
        echo "Errore nella conferma"
        return 1
    fi
}

# Funzione per fare login e ottenere token
login_user() {
    local EMAIL=$1
    local PASSWORD=$2
    
    echo -e "${YELLOW}Login utente $EMAIL...${NC}"
    
    RESPONSE=$(aws cognito-idp initiate-auth \
        --auth-flow USER_PASSWORD_AUTH \
        --client-id "$CLIENT_ID" \
        --auth-parameters USERNAME="$EMAIL",PASSWORD="$PASSWORD" \
        --region us-east-1 \
        --output json)
    
    if [ $? -eq 0 ]; then
        ID_TOKEN=$(echo "$RESPONSE" | jq -r '.AuthenticationResult.IdToken')
        echo -e "${GREEN}✓ Login effettuato${NC}"
        echo "$ID_TOKEN"
    else
        echo "Errore nel login"
        return 1
    fi
}

# Funzione per testare API
test_api() {
    local TOKEN=$1
    local ROLE=$2
    
    echo ""
    echo -e "${BLUE}=== Test API come $ROLE ===${NC}"
    
    # Test 1: Lista corsi
    echo -e "${YELLOW}Test 1: Lista corsi${NC}"
    curl -s -H "Authorization: Bearer $TOKEN" \
         "$API_URL/courses" | jq '.'
    
    # Test 2: Crea corso (solo docenti)
    if [ "$ROLE" == "docente" ]; then
        echo ""
        echo -e "${YELLOW}Test 2: Crea corso${NC}"
        curl -s -X POST \
             -H "Authorization: Bearer $TOKEN" \
             -H "Content-Type: application/json" \
             -d '{"name":"Matematica 101","description":"Corso base di matematica"}' \
             "$API_URL/courses" | jq '.'
    fi
}

# Menu principale
echo -e "${BLUE}Cosa vuoi fare?${NC}"
echo "1) Registra un nuovo docente"
echo "2) Registra un nuovo studente"
echo "3) Login come docente esistente"
echo "4) Login come studente esistente"
echo "5) Test rapido con utenti demo"
echo ""
read -p "Scelta (1-5): " CHOICE

case $CHOICE in
    1)
        read -p "Email docente: " EMAIL
        read -s -p "Password (min 8 caratteri, maiuscole, minuscole, numeri, simboli): " PASSWORD
        echo ""
        read -p "Nome: " NAME
        read -p "Cognome: " SURNAME
        
        register_user "$EMAIL" "$PASSWORD" "$NAME" "$SURNAME" "docente"
        confirm_user "$EMAIL"
        TOKEN=$(login_user "$EMAIL" "$PASSWORD")
        test_api "$TOKEN" "docente"
        ;;
        
    2)
        read -p "Email studente: " EMAIL
        read -s -p "Password (min 8 caratteri, maiuscole, minuscole, numeri, simboli): " PASSWORD
        echo ""
        read -p "Nome: " NAME
        read -p "Cognome: " SURNAME
        
        register_user "$EMAIL" "$PASSWORD" "$NAME" "$SURNAME" "studente"
        confirm_user "$EMAIL"
        TOKEN=$(login_user "$EMAIL" "$PASSWORD")
        test_api "$TOKEN" "studente"
        ;;
        
    3)
        read -p "Email docente: " EMAIL
        read -s -p "Password: " PASSWORD
        echo ""
        
        TOKEN=$(login_user "$EMAIL" "$PASSWORD")
        test_api "$TOKEN" "docente"
        ;;
        
    4)
        read -p "Email studente: " EMAIL
        read -s -p "Password: " PASSWORD
        echo ""
        
        TOKEN=$(login_user "$EMAIL" "$PASSWORD")
        test_api "$TOKEN" "studente"
        ;;
        
    5)
        echo -e "${YELLOW}Creazione utenti demo...${NC}"
        
        # Crea docente demo
        TEACHER_EMAIL="docente.demo@example.com"
        TEACHER_PASS="DemoPass123!"
        register_user "$TEACHER_EMAIL" "$TEACHER_PASS" "Mario" "Rossi" "docente"
        confirm_user "$TEACHER_EMAIL"
        
        # Crea studente demo
        STUDENT_EMAIL="studente.demo@example.com"
        STUDENT_PASS="DemoPass123!"
        register_user "$STUDENT_EMAIL" "$STUDENT_PASS" "Laura" "Bianchi" "studente"
        confirm_user "$STUDENT_EMAIL"
        
        # Test come docente
        echo ""
        echo -e "${BLUE}Test come DOCENTE${NC}"
        TEACHER_TOKEN=$(login_user "$TEACHER_EMAIL" "$TEACHER_PASS")
        test_api "$TEACHER_TOKEN" "docente"
        
        # Test come studente
        echo ""
        echo -e "${BLUE}Test come STUDENTE${NC}"
        STUDENT_TOKEN=$(login_user "$STUDENT_EMAIL" "$STUDENT_PASS")
        test_api "$STUDENT_TOKEN" "studente"
        
        echo ""
        echo -e "${GREEN}Utenti demo creati:${NC}"
        echo "Docente: $TEACHER_EMAIL / $TEACHER_PASS"
        echo "Studente: $STUDENT_EMAIL / $STUDENT_PASS"
        ;;
        
    *)
        echo "Scelta non valida"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Test completato!${NC}"
echo ""
echo "Per testare manualmente con cURL:"
echo "export TOKEN='<il-token-ottenuto>'"
echo "export API_URL='$API_URL'"
echo ""
echo "# Lista corsi"
echo 'curl -H "Authorization: Bearer $TOKEN" "$API_URL/courses" | jq'
echo ""
echo "# Crea corso (solo docenti)"
echo 'curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \\'
echo '     -d '\''{"name":"Fisica 101","description":"Introduzione alla fisica"}'\'' \\'
echo '     "$API_URL/courses" | jq'