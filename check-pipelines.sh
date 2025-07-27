#!/bin/bash
# Script to check CI/CD pipeline status

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== E-Learning Platform - Pipeline Status ===${NC}"
echo ""

# Get pipeline names from Terraform output
cd terraform
FRONTEND_PIPELINE=$(terraform output -json cicd_details | jq -r '.pipelines.frontend')
ECS_PIPELINE=$(terraform output -json cicd_details | jq -r '.pipelines.ecs')
INFRA_PIPELINE=$(terraform output -json cicd_details | jq -r '.pipelines.infrastructure')
cd ..

# Function to check pipeline status
check_pipeline() {
    local pipeline_name=$1
    local pipeline_type=$2
    
    echo -e "${YELLOW}Checking $pipeline_type Pipeline: $pipeline_name${NC}"
    
    # Get latest execution
    execution=$(aws codepipeline list-pipeline-executions \
        --pipeline-name "$pipeline_name" \
        --max-results 1 \
        --query 'pipelineExecutionSummaries[0]' \
        --output json 2>/dev/null || echo "{}")
    
    if [ "$execution" == "{}" ] || [ "$execution" == "null" ]; then
        echo -e "${RED}  ❌ No executions found${NC}"
        return
    fi
    
    status=$(echo $execution | jq -r '.status')
    execution_id=$(echo $execution | jq -r '.pipelineExecutionId')
    start_time=$(echo $execution | jq -r '.startTime')
    
    case $status in
        "Succeeded")
            echo -e "${GREEN}  ✅ Status: $status${NC}"
            ;;
        "Failed")
            echo -e "${RED}  ❌ Status: $status${NC}"
            ;;
        "InProgress")
            echo -e "${YELLOW}  ⏳ Status: $status${NC}"
            ;;
        *)
            echo -e "${BLUE}  ℹ️  Status: $status${NC}"
            ;;
    esac
    
    echo "  Execution ID: $execution_id"
    echo "  Started: $start_time"
    
    # Get stage statuses
    echo "  Stages:"
    aws codepipeline get-pipeline-execution \
        --pipeline-name "$pipeline_name" \
        --pipeline-execution-id "$execution_id" \
        --query 'pipelineExecution.artifactRevisions[0].revisionSummary' \
        --output text 2>/dev/null || echo "  No revision info available"
    
    echo ""
}

# Check each pipeline
check_pipeline "$FRONTEND_PIPELINE" "Frontend"
check_pipeline "$ECS_PIPELINE" "ECS"
check_pipeline "$INFRA_PIPELINE" "Infrastructure"

# Check CodeBuild projects
echo -e "${YELLOW}Recent CodeBuild Activity:${NC}"
aws codebuild list-builds-for-project \
    --project-name "elearning-dev-frontend-build" \
    --max-results 3 \
    --query 'ids[]' \
    --output table 2>/dev/null || echo "No recent frontend builds"

echo ""
echo -e "${BLUE}=== Quick Links ===${NC}"
echo "CodePipeline Console: https://console.aws.amazon.com/codesuite/codepipeline/pipelines"
echo "CodeBuild Console: https://console.aws.amazon.com/codesuite/codebuild/projects"
echo "CodeCommit Console: https://console.aws.amazon.com/codesuite/codecommit/repositories"