#!/bin/bash

##############################################
# API Gateway Test Script
# Tests all API endpoints with sample data
##############################################

API_BASE_URL="https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod"
TEST_USER_ID="test-user-$(date +%s)"
TEST_EMAIL="test-$(date +%s)@example.com"

echo "🧪 Testing Foody API Gateway"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

##############################################
# Test 1: Create User Profile
##############################################
echo -e "${YELLOW}Test 1: POST /users (Create User Profile)${NC}"
echo "Endpoint: $API_BASE_URL/users"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
  "$API_BASE_URL/users" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "'$TEST_USER_ID'",
    "email": "'$TEST_EMAIL'",
    "displayName": "Test User",
    "gender": "male",
    "age": 25,
    "weight": 70.5,
    "height": 175.0,
    "activityLevel": "moderate",
    "goal": "maintain",
    "dailyCalories": 2500,
    "bmi": 23.0,
    "themePreference": "dark",
    "aiProvider": "openai"
  }')

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✅ Success (HTTP $HTTP_CODE)${NC}"
  echo "$BODY" | jq '.'
else
  echo -e "${RED}❌ Failed (HTTP $HTTP_CODE)${NC}"
  echo "$BODY"
fi
echo ""

##############################################
# Test 2: Get User Profile
##############################################
echo -e "${YELLOW}Test 2: GET /users/{userId} (Get User Profile)${NC}"
echo "Endpoint: $API_BASE_URL/users/$TEST_USER_ID"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X GET \
  "$API_BASE_URL/users/$TEST_USER_ID" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✅ Success (HTTP $HTTP_CODE)${NC}"
  echo "$BODY" | jq '.'
else
  echo -e "${RED}❌ Failed (HTTP $HTTP_CODE)${NC}"
  echo "$BODY"
fi
echo ""

##############################################
# Test 3: Save Food Analysis
##############################################
echo -e "${YELLOW}Test 3: POST /food-analysis (Save Food Analysis)${NC}"
echo "Endpoint: $API_BASE_URL/food-analysis"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
  "$API_BASE_URL/food-analysis" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "'$TEST_USER_ID'",
    "imageUrl": "https://example.com/food-image.jpg",
    "foodName": "Grilled Chicken Salad",
    "calories": 350,
    "protein": 30.5,
    "carbs": 25.0,
    "fat": 12.5,
    "healthScore": 85,
    "foodId": "550e8400-e29b-41d4-a716-446655440000"
  }')

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✅ Success (HTTP $HTTP_CODE)${NC}"
  echo "$BODY" | jq '.'
else
  echo -e "${RED}❌ Failed (HTTP $HTTP_CODE)${NC}"
  echo "$BODY"
fi
echo ""

##############################################
# Test 4: Delete Food Analysis
##############################################
echo -e "${YELLOW}Test 4: DELETE /food-analysis (Delete Food Analysis)${NC}"
echo "Endpoint: $API_BASE_URL/food-analysis"
echo ""

# First, get the food ID from the created food analysis
echo "🔍 Getting food ID from created food analysis..."

# Create a food analysis first to get its UUID
CREATE_RESPONSE=$(curl -s -X POST \
  "$API_BASE_URL/food-analysis" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "'$TEST_USER_ID'",
    "imageUrl": "https://example.com/delete-test.jpg",
    "foodName": "Test Food for Deletion",
    "calories": 200,
    "protein": 15.0,
    "carbs": 20.0,
    "fat": 8.0,
    "healthScore": 75,
    "foodId": "550e8400-e29b-41d4-a716-446655440001"
  }')

FOOD_ID=$(echo "$CREATE_RESPONSE" | jq -r '.foodId // empty')

if [ -z "$FOOD_ID" ] || [ "$FOOD_ID" = "null" ]; then
  echo "❌ Could not get food ID from creation response"
  echo "Response: $CREATE_RESPONSE"
  exit 1
fi

echo "📝 Using food ID: $FOOD_ID"

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X DELETE \
  "$API_BASE_URL/food-analysis" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "'$TEST_USER_ID'",
    "foodId": "'$FOOD_ID'"
  }')

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✅ Success (HTTP $HTTP_CODE)${NC}"
  echo "$BODY" | jq '.'
else
  echo -e "${RED}❌ Failed (HTTP $HTTP_CODE)${NC}"
  echo "$BODY"
fi
echo ""

##############################################
# Test 5: Get Non-existent User (Error Test)
##############################################
echo -e "${YELLOW}Test 5: GET /users/{userId} (Non-existent User)${NC}"
echo "Endpoint: $API_BASE_URL/users/non-existent-user-id"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X GET \
  "$API_BASE_URL/users/non-existent-user-id" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" = "404" ]; then
  echo -e "${GREEN}✅ Correctly returned 404${NC}"
  echo "$BODY" | jq '.'
else
  echo -e "${RED}❌ Expected 404, got HTTP $HTTP_CODE${NC}"
  echo "$BODY"
fi
echo ""

echo "================================"
echo "🎉 API Testing Complete!"
echo ""
echo "📝 Test Summary:"
echo "  - Created user: $TEST_USER_ID"
echo "  - Email: $TEST_EMAIL"
echo ""
echo "💡 Check the database with: cd aws-lambda/test && node check-database.js"

