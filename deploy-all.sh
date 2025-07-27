#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== E-Learning Platform Complete Deployment ===${NC}"

# Step 1: Deploy base infrastructure
echo -e "${YELLOW}Step 1: Deploying base infrastructure...${NC}"
cd terraform
terraform init
terraform apply -target=module.networking -target=module.cognito -target=module.storage -target=module.messaging -target=module.compute -target=module.compute_ecs -auto-approve

# Get outputs
USER_POOL_ID=$(terraform output -json cognito_details | jq -r '.user_pool_id')
CLIENT_ID=$(terraform output -json cognito_details | jq -r '.web_client_id')
API_URL=$(terraform output -json api_details | jq -r '.api_gateway_url')
ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")

echo -e "${GREEN}Base infrastructure deployed!${NC}"

# Step 2: Build and push ECS container
echo -e "${YELLOW}Step 2: Building and pushing ECS container...${NC}"
cd ../src/ecs-container
./build-and-push.sh
cd ../..

# Step 3: Configure frontend
echo -e "${YELLOW}Step 3: Configuring frontend...${NC}"
cd src/frontend
cp .env.example .env

# Update .env file
cat > .env << EOF
REACT_APP_AWS_REGION=us-east-1
REACT_APP_USER_POOL_ID=${USER_POOL_ID}
REACT_APP_USER_POOL_CLIENT_ID=${CLIENT_ID}
REACT_APP_API_ENDPOINT=${API_URL}
EOF

echo -e "${GREEN}Frontend configured!${NC}"

# Step 4: Deploy frontend
echo -e "${YELLOW}Step 4: Deploying frontend to Elastic Beanstalk...${NC}"
chmod +x deploy.sh
./deploy.sh

# Get EB URL
ENV_URL=$(eb status | grep "CNAME:" | awk '{print $2}')

# Step 5: Update terraform with EB domain
echo -e "${YELLOW}Step 5: Updating Terraform with EB domain...${NC}"
cd ../../terraform

# Update terraform.tfvars
sed -i.bak "s/domain_name = .*/domain_name = \"${ENV_URL}\"/" terraform.tfvars

# Apply final configuration
echo -e "${YELLOW}Applying final Terraform configuration...${NC}"
terraform apply -auto-approve

echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo -e "${GREEN}Frontend URL: http://${ENV_URL}${NC}"
echo -e "${GREEN}API URL: ${API_URL}${NC}"
echo ""
echo -e "${YELLOW}To add OpenAI API key (when you have it):${NC}"
echo "aws secretsmanager put-secret-value --secret-id 'elearning-dev-openai-api-key' --secret-string 'sk-YOUR-KEY' --region us-east-1"