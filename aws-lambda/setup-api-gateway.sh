#!/bin/bash

# Setup API Gateway for Foody app

API_ID="xpdvcgcji6"
ROOT_RESOURCE_ID="c6dgtkybx9"

echo "🚀 Setting up API Gateway for Foody app..."

# Create /users resource
echo "📝 Creating /users resource..."
USERS_RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_RESOURCE_ID \
  --path-part users \
  --region us-east-1 \
  --query 'id' --output text)

# Create /users/{userId} resource
echo "📝 Creating /users/{userId} resource..."
USER_ID_RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $USERS_RESOURCE_ID \
  --path-part '{userId}' \
  --region us-east-1 \
  --query 'id' --output text)

# Create /food-analysis resource
echo "📝 Creating /food-analysis resource..."
FOOD_ANALYSIS_RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_RESOURCE_ID \
  --path-part food-analysis \
  --region us-east-1 \
  --query 'id' --output text)

# Create GET method for /users/{userId}
echo "🔧 Creating GET method for /users/{userId}..."
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $USER_ID_RESOURCE_ID \
  --http-method GET \
  --authorization-type NONE \
  --region us-east-1

# Create POST method for /users
echo "🔧 Creating POST method for /users..."
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $USERS_RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE \
  --region us-east-1

# Create POST method for /food-analysis
echo "🔧 Creating POST method for /food-analysis..."
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $FOOD_ANALYSIS_RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE \
  --region us-east-1

# Create OPTIONS methods for CORS
echo "🔧 Creating OPTIONS methods for CORS..."

# OPTIONS for /users
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $USERS_RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE \
  --region us-east-1

# OPTIONS for /users/{userId}
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $USER_ID_RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE \
  --region us-east-1

# OPTIONS for /food-analysis
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $FOOD_ANALYSIS_RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE \
  --region us-east-1

echo "✅ API Gateway setup complete!"
echo "🎉 API ID: $API_ID"
echo "📡 Base URL: https://$API_ID.execute-api.us-east-1.amazonaws.com/prod"
