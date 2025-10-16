#!/bin/bash

# Campaign Scheduler Lambda Deployment Script
# This script deploys the campaign scheduler Lambda function

set -e

echo "🕐 Deploying Campaign Scheduler Lambda Function"
echo "=============================================="
echo ""

# Configuration
FUNCTION_NAME="foody-campaign-scheduler"
HANDLER="index.handler"
RUNTIME="nodejs18.x"
ROLE_ARN="arn:aws:iam::010993883654:role/lambda-execution-role"
REGION="us-east-1"

echo "📦 Step 1: Installing dependencies..."
echo "----------------------------------------"
cd campaign-scheduler

if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
else
  echo "Dependencies already installed"
fi

echo ""
echo "📦 Step 2: Creating deployment package..."
echo "----------------------------------------"

# Create temp directory for packaging
TEMP_DIR=$(mktemp -d)
echo "Using temp directory: $TEMP_DIR"

# Copy files to temp directory
cp index.js package.json package-lock.json "$TEMP_DIR/"
cp -r node_modules "$TEMP_DIR/"

# Create zip file
cd "$TEMP_DIR"
zip -r campaign-scheduler.zip . -q
mv campaign-scheduler.zip /Users/mohammadamin/FlutterProjects/Foody/aws-lambda/

# Clean up temp directory
rm -rf "$TEMP_DIR"
cd /Users/mohammadamin/FlutterProjects/Foody/aws-lambda

echo "✓ Deployment package created"

echo ""
echo "📤 Step 3: Uploading to AWS Lambda..."
echo "----------------------------------------"

# Check if function exists
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "Function exists - updating code..."
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://campaign-scheduler.zip \
    --region "$REGION"
else
  echo "Function doesn't exist - creating new function..."
  aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime "$RUNTIME" \
    --role "$ROLE_ARN" \
    --handler "$HANDLER" \
    --zip-file fileb://campaign-scheduler.zip \
    --timeout 60 \
    --memory-size 256 \
    --region "$REGION"
fi

echo ""
echo "🔧 Step 4: Setting environment variables..."
echo "----------------------------------------"

# Load environment variables from .env file
if [ -f ".env" ]; then
  echo "Loading environment variables from .env..."
  
  # Read .env file and create JSON for Lambda
  ENV_JSON=$(cat .env | grep -v '^#' | grep -v '^$' | awk -F= '{printf "\"%s\":\"%s\",", $1, $2}' | sed 's/,$//')
  
  aws lambda update-function-configuration \
    --function-name "$FUNCTION_NAME" \
    --environment "Variables={$ENV_JSON}" \
    --region "$REGION"
else
  echo "No .env file found - using default environment variables"
fi

echo ""
echo "✅ Deployment completed successfully!"
echo "=============================================="
echo "Function Name: $FUNCTION_NAME"
echo "Region: $REGION"
echo "Handler: $HANDLER"
echo "Runtime: $RUNTIME"
echo ""
echo "Next steps:"
echo "1. Create EventBridge rule to trigger this function every minute"
echo "2. Test the scheduler with a scheduled campaign"
echo ""
