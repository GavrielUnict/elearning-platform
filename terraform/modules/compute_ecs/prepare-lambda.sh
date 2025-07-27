#!/bin/bash

# Prepara il file ZIP per Lambda Orchestrator

cd functions/ecs-orchestrator
npm init -y
npm install @aws-sdk/client-ecs @aws-sdk/client-auto-scaling
zip -r ../ecs-orchestrator.zip .
cd ../..