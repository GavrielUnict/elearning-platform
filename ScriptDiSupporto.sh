#!/usr/bin/env bash
set -euo pipefail

echo "📁 Creazione file per moduli CI/CD, buildspec e script..."

# === 1. Modulo Terraform CI/CD ===
touch terraform/modules/cicd/main.tf
touch terraform/modules/cicd/iam.tf
touch terraform/modules/cicd/codebuild.tf
touch terraform/modules/cicd/pipelines.tf
touch terraform/modules/cicd/triggers.tf
touch terraform/modules/cicd/variables.tf
touch terraform/modules/cicd/outputs.tf
touch terraform/modules/cicd/README.md

# === 2. Buildspec Files ===
mkdir -p buildspec
touch buildspec/frontend-buildspec.yml
touch buildspec/ecs-buildspec.yml
touch buildspec/terraform-plan-buildspec.yml
touch buildspec/terraform-apply-buildspec.yml

# === 3. Script e Guide ===
touch setup-cicd.sh
touch check-pipelines.sh
touch GUIDA_CICD_COMPLETA.md

echo "✅ Tutti i file CI/CD creati con successo."
