#!/bin/bash

# Script per build e push del container Docker

set -e

# Ottiengo i dettagli da Terraform
# cd ../../terraform
# ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
# cd ../src/ecs-container 

ECR_URL="323395044516.dkr.ecr.us-east-1.amazonaws.com/elearning-dev-quiz-processor"

if [ -z "$ECR_URL" ]; then
    echo "Error: Could not get ECR repository URL from Terraform"
    exit 1
fi

# Extract region and registry from ECR URL
REGION=$(echo $ECR_URL | cut -d'.' -f4)
REGISTRY=$(echo $ECR_URL | cut -d'/' -f1)

echo "ECR Repository: $ECR_URL"
echo "Region: $REGION"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY

# Build image
echo "Building Docker image..."
docker build -t quiz-processor .

# Tag image
echo "Tagging image..."
docker tag quiz-processor:latest $ECR_URL:latest

# Push image
echo "Pushing image to ECR..."
docker push $ECR_URL:latest

echo "Done! Image pushed to $ECR_URL:latest"