#!/bin/bash
echo "🔄 Rolling back to stable version..."

# Rollback Lambda functions
aws lambda update-function-code \
  --function-name foody-food-analysis \
  --zip-file fileb://food-analysis-stable.zip

aws lambda update-function-code \
  --function-name foody-user-profile \
  --zip-file fileb://user-profile-stable.zip

echo "✅ Rollback completed!"
