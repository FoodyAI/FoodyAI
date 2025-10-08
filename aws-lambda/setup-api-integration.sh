#!/bin/bash

# Setup API Gateway integration with Lambda functions

API_ID="xpdvcgcji6"
REGION="us-east-1"

echo "🔧 Setting up API Gateway integration with Lambda functions..."

# Get the root resource ID
ROOT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[0].id' --output text)

# Get resource IDs
USERS_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?pathPart==`users`].id' --output text)
USER_ID_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?pathPart==`{userId}`].id' --output text)
FOOD_ANALYSIS_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?pathPart==`food-analysis`].id' --output text)

echo "📋 Resource IDs:"
echo "  - Users: $USERS_RESOURCE_ID"
echo "  - User ID: $USER_ID_RESOURCE_ID" 
echo "  - Food Analysis: $FOOD_ANALYSIS_RESOURCE_ID"

# Create Lambda integration for GET /users/{userId}
echo "🔗 Creating integration for GET /users/{userId}..."
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $USER_ID_RESOURCE_ID \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:010993883654:function:foody-user-profile/invocations" \
  --region $REGION

# Create Lambda integration for POST /users
echo "🔗 Creating integration for POST /users..."
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $USERS_RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:010993883654:function:foody-user-profile/invocations" \
  --region $REGION

# Create Lambda integration for POST /food-analysis
echo "🔗 Creating integration for POST /food-analysis..."
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $FOOD_ANALYSIS_RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:010993883654:function:foody-food-analysis/invocations" \
  --region $REGION

# Add Lambda permissions for API Gateway
echo "🔐 Adding Lambda permissions for API Gateway..."

# Permission for user-profile Lambda
aws lambda add-permission \
  --function-name foody-user-profile \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:010993883654:$API_ID/*/*" \
  --region $REGION

# Permission for food-analysis Lambda
aws lambda add-permission \
  --function-name foody-food-analysis \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:010993883654:$API_ID/*/*" \
  --region $REGION

# Deploy the API
echo "🚀 Deploying API Gateway..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region $REGION

echo "✅ API Gateway integration complete!"
echo "📡 API Base URL: https://$API_ID.execute-api.$REGION.amazonaws.com/prod"
