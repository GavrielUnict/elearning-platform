#!/bin/bash

echo "=== Preparazione Lambda Functions e Layer ==="
echo ""

# Colori
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directory base
BASE_DIR="$(pwd)"
FUNCTIONS_DIR="$BASE_DIR/functions"
LAYERS_DIR="$BASE_DIR/layers"

# Crea directory se non esistono
mkdir -p "$FUNCTIONS_DIR"
mkdir -p "$LAYERS_DIR/shared/nodejs"

# ====================
# SHARED LAYER
# ====================
echo -e "${YELLOW}Preparazione Shared Layer...${NC}"

cd "$LAYERS_DIR/shared"

# Crea package.json per il layer
cat > nodejs/package.json << 'EOF'
{
  "name": "shared-layer",
  "version": "1.0.0",
  "description": "Shared utilities for Lambda functions",
  "main": "utils.js"
}
EOF

# Crea il file ZIP del layer
zip -r ../shared-layer.zip nodejs/
echo -e "${GREEN}✓ shared-layer.zip creato${NC}"

# ====================
# LAMBDA FUNCTIONS
# ====================
echo ""
echo -e "${YELLOW}Preparazione Lambda Functions...${NC}"

# Lista delle funzioni da creare
FUNCTIONS=(
    "create-course"
    "list-courses"
    "manage-course"
    "request-enrollment"
    "approve-enrollment"
    "list-enrollments"
    "get-presigned-url"
    "list-documents"
    "manage-document"
    "get-quiz"
    "submit-quiz-results"
    "list-results"
)

# Per ogni funzione, crea directory e ZIP
for FUNCTION in "${FUNCTIONS[@]}"; do
    FUNCTION_DIR="$FUNCTIONS_DIR/$FUNCTION"
    mkdir -p "$FUNCTION_DIR"
    
    # Se il file index.js non esiste, crea un placeholder
    if [ ! -f "$FUNCTION_DIR/index.js" ]; then
        cat > "$FUNCTION_DIR/index.js" << EOF
const { createResponse } = require('/opt/nodejs/utils');

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    return createResponse(200, {
        message: 'Function ${FUNCTION} not yet implemented',
        functionName: '${FUNCTION}',
        timestamp: new Date().toISOString()
    });
};
EOF
    fi
    
    # Crea ZIP
    cd "$FUNCTION_DIR"
    zip -r "../${FUNCTION}.zip" index.js
    echo -e "${GREEN}✓ ${FUNCTION}.zip creato${NC}"
done

echo ""
echo -e "${GREEN}✅ Tutte le Lambda functions sono state preparate!${NC}"
echo ""
echo "Prossimi passi:"
echo "1. Implementa il codice mancante nelle Lambda functions"
echo "2. Esegui 'terraform plan' e 'terraform apply'"

cd "$BASE_DIR"