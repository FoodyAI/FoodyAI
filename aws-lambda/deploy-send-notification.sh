#!/bin/bash

# deploy-send-notification.sh
# Deployment script for send-notification Lambda function

set -e  # Exit on error

echo "🚀 Deploying send-notification Lambda Function"
echo "=============================================="

# Configuration
FUNCTION_NAME="foody-send-notification"
REGION="us-east-1"
RUNTIME="nodejs18.x"
HANDLER="index.handler"
ROLE_ARN="arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role"  # Replace with your role ARN

# Navigate to Lambda root directory
cd "$(dirname "$0")"

echo ""
echo "📦 Step 1: Installing dependencies..."
echo "----------------------------------------"

# Install all dependencies including firebase-admin
if [ ! -d "node_modules" ]; then
  echo "Installing node modules in root directory..."
  npm install
fi

echo ""
echo "📦 Step 2: Creating deployment package..."
echo "----------------------------------------"

# Create temp directory
TEMP_DIR=$(mktemp -d)
echo "Using temp directory: $TEMP_DIR"

# Copy send-notification function
echo "Copying send-notification function..."
cp -r send-notification "$TEMP_DIR/"

# Copy shared dependencies
echo "Copying shared dependencies..."
cp firebase-admin.js "$TEMP_DIR/send-notification/"
cp notification-helpers.js "$TEMP_DIR/send-notification/"

# Copy node_modules
echo "Copying node_modules..."
cp -r node_modules "$TEMP_DIR/send-notification/"

# Navigate to temp directory
cd "$TEMP_DIR/send-notification"

# Create ZIP package
echo "Creating ZIP package..."
zip -r ../send-notification.zip . > /dev/null

echo ""
echo "📤 Step 3: Uploading to AWS Lambda..."
echo "----------------------------------------"

# Check if function exists
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" > /dev/null 2>&1; then
  echo "Function exists - updating code..."
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://../send-notification.zip \
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
    --zip-file fileb://../send-notification.zip \
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
echo "  - Resource: /send-notification"
echo "  - Method: POST"
echo "  - Integration: Lambda Function ($FUNCTION_NAME)"
echo "  - CORS enabled"

echo ""
echo "🧹 Step 6: Cleanup..."
echo "----------------------------------------"

# Cleanup temp directory
cd -
rm -rf "$TEMP_DIR"
echo "✓ Cleaned up temporary files"

echo ""
echo "✅ Deployment Complete!"
echo "=============================================="
echo ""
echo "Function Name: $FUNCTION_NAME"
echo "Region: $REGION"
echo "Runtime: $RUNTIME"
echo ""
echo "Next steps:"
echo "1. Configure API Gateway endpoint"
echo "2. Test the function with test events"
echo "3. Monitor CloudWatch logs for any issues"
echo ""
echo "Test command:"
echo "aws lambda invoke --function-name $FUNCTION_NAME --payload file://test-event.json response.json --region $REGION"
echo ""
