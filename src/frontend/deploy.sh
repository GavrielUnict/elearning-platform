#!/bin/bash

set -e

# Colors for output 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if EB CLI is installed
if ! command -v eb &> /dev/null; then
    echo -e "${RED}EB CLI not found. Please install it first.${NC}"
    echo "pip install awsebcli"
    exit 1
fi

# Check if .env file exists 
if [ ! -f ".env.production" ]; then
    echo -e "${RED}.env file not found!${NC}"
    echo "Please copy .env.example to .env and configure it:"
    echo "cp .env.example .env"
    exit 1
fi

# Initialize EB CLI if not already done
if [ ! -d ".elasticbeanstalk" ]; then
    echo -e "${YELLOW}Initializing Elastic Beanstalk...${NC}"
    eb init -p "Docker running on 64bit Amazon Linux 2" elearning-dev-frontend --region us-east-1
fi

echo -e "${YELLOW}Installing dependencies...${NC}"
npm install

echo -e "${YELLOW}Building React app...${NC}"
npm run build

echo -e "${YELLOW}Creating deployment package...${NC}"
# Remove old zip if exists
rm -f deploy.zip
# Create new zip with necessary files
zip -r deploy.zip Dockerfile Dockerrun.aws.json nginx.conf build/ package.json -x "*.git*" "node_modules/*"

# Check if environment exists
# if ! eb list | grep -q "elearning-dev"; then
#     echo -e "${YELLOW}Creating new Elastic Beanstalk environment...${NC}"
#     eb create elearning-dev --instance-type t3.medium --envvars $(cat .env | grep -v '^#' | xargs | tr ' ' ',')
# else
#     echo -e "${YELLOW}Deploying to existing environment...${NC}"
#     eb deploy
# fi

# Using the existing environment created by Terraform
echo -e "${YELLOW}Deploying to existing environment...${NC}"
eb use elearning-dev-frontend-env
eb deploy


echo -e "${GREEN}Getting environment info...${NC}"
eb status

# Get the environment URL
ENV_URL=$(eb status | grep "CNAME:" | awk '{print $2}')
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}Frontend URL: http://${ENV_URL}${NC}"
# echo ""
# echo -e "${YELLOW}Next steps:${NC}"
# echo "1. Update domain_name in terraform.tfvars with: ${ENV_URL}"
# echo "2. Run 'terraform apply' to update CORS settings"