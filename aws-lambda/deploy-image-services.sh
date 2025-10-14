#!/bin/bash

# Foody App - Image Services Deployment Script
# This script deploys the image upload and serve Lambda functions

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGION="us-east-1"
LAMBDA_ROLE_ARN="arn:aws:iam::010993883654:role/lambda-execution-role"
IMAGE_UPLOAD_FUNCTION_NAME="foody-image-upload"
IMAGE_SERVE_FUNCTION_NAME="foody-image-serve"

echo -e "${BLUE}🚀 Starting Foody Image Services Deployment...${NC}"
echo ""

# Function to deploy a Lambda function
deploy_lambda() {
    local function_name=$1
    local function_dir=$2
    local description=$3
    
    echo -e "${YELLOW}📦 Deploying $function_name...${NC}"
    
    # Navigate to function directory
    cd "$function_dir"
    
    # Install dependencies
    echo "📥 Installing dependencies..."
    npm install --production
    
    # Create deployment package
    echo "📦 Creating deployment package..."
    zip -r "../${function_name}.zip" . -x "*.git*" "*.DS_Store*" "node_modules/.cache/*"
    
    # Go back to parent directory
    cd ..
    
    # Check if function exists
    if aws lambda get-function --function-name "$function_name" --region "$REGION" >/dev/null 2>&1; then
        echo "🔄 Updating existing function: $function_name"
        aws lambda update-function-code \
            --function-name "$function_name" \
            --zip-file "fileb://${function_name}.zip" \
            --region "$REGION"
    else
        echo "🆕 Creating new function: $function_name"
        aws lambda create-function \
            --function-name "$function_name" \
            --runtime nodejs18.x \
            --role "$LAMBDA_ROLE_ARN" \
            --handler index.handler \
            --zip-file "fileb://${function_name}.zip" \
            --description "$description" \
            --region "$REGION"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $function_name deployed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to deploy $function_name${NC}"
        exit 1
    fi
    
    # Clean up zip file
    rm "${function_name}.zip"
    echo ""
}

# Deploy Image Upload Lambda
deploy_lambda "$IMAGE_UPLOAD_FUNCTION_NAME" "image-upload" "Foody App - Image Upload Service"

# Deploy Image Serve Lambda
deploy_lambda "$IMAGE_SERVE_FUNCTION_NAME" "image-serve" "Foody App - Image Serve Service"

echo -e "${GREEN}🎉 All image services deployed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Deployed Functions:${NC}"
echo "  • $IMAGE_UPLOAD_FUNCTION_NAME"
echo "  • $IMAGE_SERVE_FUNCTION_NAME"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "  1. Configure API Gateway endpoints"
echo "  2. Update Flutter app to use new endpoints"
echo "  3. Test the complete image upload and serve flow"
