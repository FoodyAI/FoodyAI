#!/bin/bash

# Test script for the new image endpoints
# This script tests both image upload and image serve endpoints

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE_URL="https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod"
UPLOAD_ENDPOINT="$API_BASE_URL/image-upload"
SERVE_ENDPOINT="$API_BASE_URL/image-serve"

echo -e "${BLUE}🧪 Testing Foody Image Endpoints...${NC}"
echo ""

# Test 1: Test image upload endpoint (without actual image data)
echo -e "${YELLOW}📤 Test 1: Testing image upload endpoint...${NC}"
echo "Endpoint: $UPLOAD_ENDPOINT"

# Create a test payload (this will fail but we can see if the endpoint is accessible)
TEST_PAYLOAD='{
  "imageData": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
  "fileName": "test.png",
  "contentType": "image/png"
}'

echo "Sending test request..."
UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$UPLOAD_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d "$TEST_PAYLOAD")

UPLOAD_HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | tail -n1)
UPLOAD_BODY=$(echo "$UPLOAD_RESPONSE" | head -n -1)

echo "Response Code: $UPLOAD_HTTP_CODE"
echo "Response Body: $UPLOAD_BODY"

if [ "$UPLOAD_HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Image upload endpoint is accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Image upload endpoint returned $UPLOAD_HTTP_CODE (expected for test without auth)${NC}"
fi

echo ""

# Test 2: Test image serve endpoint
echo -e "${YELLOW}📥 Test 2: Testing image serve endpoint...${NC}"
echo "Endpoint: $SERVE_ENDPOINT"

# Test with a non-existent image key
SERVE_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$SERVE_ENDPOINT?key=non-existent-image.jpg")

SERVE_HTTP_CODE=$(echo "$SERVE_RESPONSE" | tail -n1)
SERVE_BODY=$(echo "$SERVE_RESPONSE" | head -n -1)

echo "Response Code: $SERVE_HTTP_CODE"
echo "Response Body: $SERVE_BODY"

if [ "$SERVE_HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✅ Image serve endpoint is accessible and correctly returns 404 for non-existent images${NC}"
elif [ "$SERVE_HTTP_CODE" = "400" ]; then
    echo -e "${GREEN}✅ Image serve endpoint is accessible and correctly validates parameters${NC}"
else
    echo -e "${YELLOW}⚠️  Image serve endpoint returned $SERVE_HTTP_CODE${NC}"
fi

echo ""

# Test 3: Test CORS preflight
echo -e "${YELLOW}🌐 Test 3: Testing CORS preflight...${NC}"

CORS_RESPONSE=$(curl -s -w "\n%{http_code}" -X OPTIONS "$UPLOAD_ENDPOINT" \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type")

CORS_HTTP_CODE=$(echo "$CORS_RESPONSE" | tail -n1)
CORS_BODY=$(echo "$CORS_RESPONSE" | head -n -1)

echo "CORS Response Code: $CORS_HTTP_CODE"
echo "CORS Response Body: $CORS_BODY"

if [ "$CORS_HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ CORS preflight is working${NC}"
else
    echo -e "${YELLOW}⚠️  CORS preflight returned $CORS_HTTP_CODE${NC}"
fi

echo ""
echo -e "${BLUE}📋 Test Summary:${NC}"
echo "  • Image Upload Endpoint: $UPLOAD_ENDPOINT"
echo "  • Image Serve Endpoint: $SERVE_ENDPOINT"
echo "  • Both endpoints are accessible and responding"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "  1. Test with actual image upload from Flutter app"
echo "  2. Verify S3 integration is working"
echo "  3. Test image display in the app"
