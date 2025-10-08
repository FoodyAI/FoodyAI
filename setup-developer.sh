#!/bin/bash

# 🚀 Foody Developer Setup Script
# Run this script to set up your development environment

echo "🚀 Setting up Foody development environment..."
echo "=============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js: $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ Node.js not found. Please install Node.js v18+${NC}"
    exit 1
fi

# Check Flutter
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "${GREEN}✅ Flutter: $FLUTTER_VERSION${NC}"
else
    echo -e "${RED}❌ Flutter not found. Please install Flutter SDK${NC}"
    exit 1
fi

# Check AWS CLI
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version)
    echo -e "${GREEN}✅ AWS CLI: $AWS_VERSION${NC}"
else
    echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI${NC}"
    exit 1
fi

# Check jq
if command -v jq &> /dev/null; then
    echo -e "${GREEN}✅ jq: $(jq --version)${NC}"
else
    echo -e "${RED}❌ jq not found. Please install jq${NC}"
    exit 1
fi

echo ""

# Setup AWS Lambda dependencies
echo -e "${BLUE}📦 Setting up backend dependencies...${NC}"
cd aws-lambda

# Install user-profile dependencies
echo "Installing user-profile dependencies..."
cd user-profile
npm install
cd ..

# Install food-analysis dependencies  
echo "Installing food-analysis dependencies..."
cd food-analysis
npm install
cd ..

# Install test dependencies
echo "Installing test dependencies..."
cd test
npm install
cd ..

echo -e "${GREEN}✅ Backend dependencies installed${NC}"
echo ""

# Setup Flutter dependencies
echo -e "${BLUE}📱 Setting up Flutter dependencies...${NC}"
cd ..
flutter pub get

echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
echo ""

# Test AWS connection
echo -e "${BLUE}🔐 Testing AWS connection...${NC}"
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✅ AWS connection successful${NC}"
else
    echo -e "${RED}❌ AWS connection failed. Please configure AWS CLI${NC}"
    echo "Run: aws configure"
    echo "Use the credentials provided in the onboarding guide"
    exit 1
fi

echo ""

# Test backend API
echo -e "${BLUE}🧪 Testing backend API...${NC}"
cd aws-lambda/test
chmod +x test-api.sh
if ./test-api.sh &> /dev/null; then
    echo -e "${GREEN}✅ Backend API is working${NC}"
else
    echo -e "${YELLOW}⚠️  Backend API test failed. Check your AWS configuration${NC}"
fi

echo ""

# Test database connection
echo -e "${BLUE}🗄️  Testing database connection...${NC}"
if node check-database.js &> /dev/null; then
    echo -e "${GREEN}✅ Database connection successful${NC}"
else
    echo -e "${YELLOW}⚠️  Database connection failed. Check network connectivity${NC}"
fi

echo ""
echo "=============================================="
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Configure AWS: aws configure (get credentials from team lead)"
echo "2. Test backend: cd aws-lambda/test && ./test-api.sh"
echo "3. Test Flutter app: flutter run"
echo "4. Start contributing to the project!"
echo ""
echo -e "${BLUE}🔗 Useful commands:${NC}"
echo "• Test backend: cd aws-lambda/test && ./test-api.sh"
echo "• Check database: cd aws-lambda && node database-manager.js users"
echo "• Run Flutter app: flutter run"
echo "• Database help: cd aws-lambda && node database-manager.js help"
echo ""
echo -e "${BLUE}🆘 Need help?${NC}"
echo "• AWS issues: Contact team lead for credentials"
echo "• Setup issues: Check this script output above"
echo "• Database issues: Run 'node database-manager.js help'"
echo "• Flutter issues: Check Flutter console output"
echo ""
echo -e "${GREEN}Welcome to the Foody team! 🚀${NC}"
