#!/bin/bash

# Deploy AWS Lambda functions for Foody app

echo "🚀 Deploying AWS Lambda functions for Foody app..."

# Create deployment packages
echo "📦 Creating deployment packages..."

# Food Analysis Lambda
cd food-analysis
npm install
zip -r ../food-analysis.zip .
cd ..

# User Profile Lambda
cd user-profile
npm install
zip -r ../user-profile.zip .
cd ..

# Create Lambda functions
echo "🔧 Creating Lambda functions..."

# Food Analysis Lambda
aws lambda create-function \
  --function-name foody-food-analysis \
  --runtime nodejs18.x \
  --role arn:aws:iam::010993883654:role/lambda-execution-role \
  --handler index.handler \
  --zip-file fileb://food-analysis.zip \
  --region us-east-1

# User Profile Lambda
aws lambda create-function \
  --function-name foody-user-profile \
  --runtime nodejs18.x \
  --role arn:aws:iam::010993883654:role/lambda-execution-role \
  --handler index.handler \
  --zip-file fileb://user-profile.zip \
  --region us-east-1

echo "✅ Lambda functions deployed successfully!"

# Clean up
rm food-analysis.zip user-profile.zip

echo "🎉 Deployment complete!"
