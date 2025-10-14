#!/bin/bash

# Foody App - Image Endpoints API Gateway Configuration Script
# This script configures API Gateway endpoints for image upload and serve services

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_NAME="foody-api"
REGION="us-east-1"
IMAGE_UPLOAD_LAMBDA_NAME="foody-image-upload"
IMAGE_SERVE_LAMBDA_NAME="foody-image-serve"
LAMBDA_ROLE_ARN="arn:aws:iam::010993883654:role/lambda-execution-role"

echo -e "${BLUE}🚀 Configuring API Gateway for Foody Image Services...${NC}"
echo ""

# Function to get API ID
get_api_id() {
    aws apigateway get-rest-apis --region $REGION --query "items[?name=='$API_NAME'].id" --output text
}

# Function to get Root Resource ID
get_root_resource_id() {
    aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/'].id" --output text
}

# Function to create endpoint
create_endpoint() {
    local resource_path=$1
    local lambda_name=$2
    local http_method=$3
    local description=$4
    
    echo -e "${YELLOW}🔧 Creating $http_method /$resource_path endpoint...${NC}"
    
    # Get or create resource
    local resource_id=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/$resource_path'].id" --output text)
    
    if [ -z "$resource_id" ]; then
        echo "📝 Creating /$resource_path resource..."
        resource_id=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_RESOURCE_ID --path-part $resource_path --region $REGION --query 'id' --output text)
        echo "✅ Created /$resource_path Resource ID: $resource_id"
    else
        echo "✅ /$resource_path resource already exists (ID: $resource_id)"
    fi
    
    # Create method
    echo "📝 Creating $http_method method for /$resource_path..."
    aws apigateway put-method --rest-api-id $API_ID --resource-id $resource_id --http-method $http_method --authorization-type NONE --region $REGION --no-api-key
    
    # Set up Lambda integration
    echo "📝 Setting up Lambda integration for $http_method /$resource_path..."
    local lambda_arn=$(aws lambda get-function --function-name $lambda_name --region $REGION --query 'Configuration.FunctionArn' --output text)
    
    if [ -z "$lambda_arn" ]; then
        echo -e "${RED}❌ Lambda function '$lambda_name' not found. Please ensure it exists.${NC}"
        exit 1
    fi
    echo "✅ Found Lambda ARN: $lambda_arn"
    
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $resource_id --http-method $http_method --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$lambda_arn/invocations --region $REGION
    
    # Add permissions for API Gateway to invoke Lambda
    echo "📝 Adding Lambda invocation permissions for API Gateway..."
    local permission_statement_id="ApiGatewayInvokeLambda-${lambda_name}-${resource_path}"
    
    # Remove existing permission if it exists to avoid "statement already exists" error
    aws lambda remove-permission \
        --function-name $lambda_name \
        --statement-id $permission_statement_id \
        --region $REGION 2>/dev/null || true
    
    aws lambda add-permission \
        --function-name $lambda_name \
        --statement-id $permission_statement_id \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:$REGION:$AWS_ACCOUNT_ID:$API_ID/*/*" \
        --region $REGION
    
    # Enable CORS for the method
    echo "📝 Enabling CORS for $http_method /$resource_path method..."
    aws apigateway put-method --rest-api-id $API_ID --resource-id $resource_id --http-method OPTIONS --authorization-type NONE --region $REGION
    aws apigateway put-integration --rest-api-id $API_ID --resource-id $resource_id --http-method OPTIONS --type MOCK --region $REGION
    aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $resource_id --http-method OPTIONS --status-code 200 --response-templates '{"application/json": ""}' --region $REGION
    aws apigateway put-method-response --rest-api-id $API_ID --resource-id $resource_id --http-method OPTIONS --status-code 200 --response-models '{"application/json": "Empty"}' --response-parameters 'method.response.header.Access-Control-Allow-Headers':true,'method.response.header.Access-Control-Allow-Methods':true,'method.response.header.Access-Control-Allow-Origin':true --region $REGION
    aws apigateway put-integration-response --rest-api-id $API_ID --resource-id $resource_id --http-method OPTIONS --status-code 200 --response-parameters 'method.response.header.Access-Control-Allow-Headers':"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",'method.response.header.Access-Control-Allow-Methods':"'$http_method,OPTIONS'",'method.response.header.Access-Control-Allow-Origin':"'"*"'" --region $REGION
    
    echo -e "${GREEN}✅ $http_method /$resource_path endpoint configured successfully${NC}"
    echo ""
}

# Main execution
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ AWS_ACCOUNT_ID environment variable is not set. Please set it before running this script.${NC}"
    exit 1
fi

# Get API ID
API_ID=$(get_api_id)
if [ -z "$API_ID" ]; then
    echo -e "${RED}❌ API Gateway '$API_NAME' not found. Please ensure it exists.${NC}"
    exit 1
fi
echo "✅ Found API Gateway ID: $API_ID"

# Get Root Resource ID
ROOT_RESOURCE_ID=$(get_root_resource_id)
echo "✅ Found Root Resource ID: $ROOT_RESOURCE_ID"
echo ""

# Create image upload endpoint
create_endpoint "image-upload" $IMAGE_UPLOAD_LAMBDA_NAME "POST" "Upload food images to S3"

# Create image serve endpoint
create_endpoint "image-serve" $IMAGE_SERVE_LAMBDA_NAME "GET" "Serve food images from S3"

# Deploy API
echo -e "${YELLOW}🚀 Deploying API Gateway...${NC}"
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --region $REGION --description "Deploying image services endpoints"

echo -e "${GREEN}🎉 API Gateway configuration complete!${NC}"
echo ""
echo -e "${BLUE}📋 Configured Endpoints:${NC}"
echo "  • POST /image-upload - Upload images to S3"
echo "  • GET /image-serve - Serve images from S3"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "  1. Update Flutter app to use new endpoints"
echo "  2. Test the complete image upload and serve flow"
