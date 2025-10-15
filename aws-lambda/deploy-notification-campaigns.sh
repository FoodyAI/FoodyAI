#!/bin/bash

# deploy-notification-campaigns.sh
# Deployment script for notification campaigns Lambda function

set -e

echo "🚀 Deploying Notification Campaigns Lambda Function"
echo "=================================================="

# Configuration
FUNCTION_NAME="foody-notification-campaigns"
RUNTIME="nodejs18.x"
HANDLER="index.handler"
REGION="us-east-1"
ROLE_ARN="arn:aws:iam::010993883654:role/lambda-execution-role"

echo ""
echo "📦 Step 1: Installing dependencies..."
echo "----------------------------------------"

cd notification-campaigns

if [ ! -d "node_modules" ]; then
  echo "Installing npm dependencies..."
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

# Copy function files
cp index.js "$TEMP_DIR/"
cp package.json "$TEMP_DIR/"
cp -r node_modules "$TEMP_DIR/"

# Create ZIP package
cd "$TEMP_DIR"
zip -r ../notification-campaigns.zip . > /dev/null
cd - > /dev/null

echo "✓ Deployment package created"

echo ""
echo "📤 Step 3: Uploading to AWS Lambda..."
echo "----------------------------------------"

# Check if function exists
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" > /dev/null 2>&1; then
  echo "Function exists - updating code..."
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://../notification-campaigns.zip \
    --region "$REGION"

  echo "Waiting for update to complete..."
  aws lambda wait function-updated --function-name "$FUNCTION_NAME" --region "$REGION"

  echo "Updating function configuration..."
  aws lambda update-function-configuration \
    --function-name "$FUNCTION_NAME" \
    --runtime "$RUNTIME" \
    --handler "$HANDLER" \
    --timeout 60 \
    --memory-size 512 \
    --region "$REGION"

else
  echo "Function does not exist - creating new function..."
  aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime "$RUNTIME" \
    --role "$ROLE_ARN" \
    --handler "$HANDLER" \
    --zip-file fileb://../notification-campaigns.zip \
    --timeout 60 \
    --memory-size 512 \
    --region "$REGION"
fi

echo ""
echo "🔧 Step 4: Setting environment variables..."
echo "----------------------------------------"

# Load environment variables from .env file
if [ -f "../.env" ]; then
  echo "Loading environment variables from .env..."

  # Read .env file and create JSON for Lambda
  ENV_JSON=$(cat ../.env | grep -v '^#' | grep -v '^$' | awk -F= '{printf "\"%s\":\"%s\",", $1, $2}' | sed 's/,$//')

  aws lambda update-function-configuration \
    --function-name "$FUNCTION_NAME" \
    --environment "Variables={$ENV_JSON}" \
    --region "$REGION" > /dev/null

  echo "✓ Environment variables updated"
else
  echo "⚠️  .env file not found - skipping environment variables"
fi

echo ""
echo "🌐 Step 5: Setting up API Gateway (if not exists)..."
echo "----------------------------------------"

# Note: You'll need to manually create API Gateway endpoint or use AWS CDK/CloudFormation
echo "Please ensure API Gateway is configured with:"
echo "  - Resource: /campaigns"
echo "  - Methods: GET, POST, PUT, DELETE"
echo "  - Integration: Lambda Function ($FUNCTION_NAME)"
echo "  - CORS enabled"

echo ""
echo "🧹 Step 6: Cleanup..."
echo "----------------------------------------"

# Clean up temp files
rm -rf "$TEMP_DIR"
rm -f ../notification-campaigns.zip

echo "✓ Cleaned up temporary files"

echo ""
echo "✅ Deployment Complete!"
echo "=================================================="
echo ""
echo "Function Name: $FUNCTION_NAME"
echo "Region: $REGION"
echo "Runtime: $RUNTIME"
echo ""
echo "Next steps:"
echo "1. Configure API Gateway endpoints"
echo "2. Test the function with test events"
echo "3. Monitor CloudWatch logs for any issues"
echo ""
echo "Test command:"
echo "aws lambda invoke --function-name $FUNCTION_NAME --payload file://test-event.json response.json --region $REGION"
