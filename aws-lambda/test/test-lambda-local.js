#!/usr/bin/env node

/**
 * Local Lambda Function Test
 * Tests Lambda functions locally with sample API Gateway events
 */

// Mock API Gateway event for user profile creation
const createUserEvent = {
  httpMethod: 'POST',
  path: '/users',
  pathParameters: null,
  body: JSON.stringify({
    userId: 'test-local-' + Date.now(),
    email: 'test-local@example.com',
    displayName: 'Local Test User',
    gender: 'female',
    age: 28,
    weight: 65.0,
    height: 165.0,
    activityLevel: 'active',
    goal: 'lose',
    dailyCalories: 2000,
    bmi: 23.9,
    themePreference: 'system',
    aiProvider: 'openai'
  }),
  headers: {
    'Content-Type': 'application/json'
  }
};

// Mock API Gateway event for getting user profile
const getUserEvent = {
  httpMethod: 'GET',
  path: '/users/test-user-123',
  pathParameters: {
    userId: 'test-user-123'
  },
  body: null,
  headers: {
    'Content-Type': 'application/json'
  }
};

// Mock API Gateway event for food analysis
const createFoodAnalysisEvent = {
  httpMethod: 'POST',
  path: '/food-analysis',
  pathParameters: null,
  body: JSON.stringify({
    userId: 'test-user-123',
    imageUrl: 'https://example.com/pizza.jpg',
    foodName: 'Margherita Pizza',
    calories: 800,
    protein: 35.0,
    carbs: 90.0,
    fat: 28.0,
    healthScore: 65
  }),
  headers: {
    'Content-Type': 'application/json'
  }
};

async function testUserProfileLambda() {
  console.log('🧪 Testing User Profile Lambda Function\n');
  console.log('═══════════════════════════════════════════════\n');
  
  try {
    // Import the Lambda handler
    const { handler } = require('../user-profile/index.js');
    
    // Test 1: Create User
    console.log('📝 Test 1: Create User Profile');
    console.log('Request:', JSON.stringify(JSON.parse(createUserEvent.body), null, 2));
    const createResult = await handler(createUserEvent);
    console.log('Response Status:', createResult.statusCode);
    console.log('Response Body:', JSON.parse(createResult.body));
    console.log('');
    
    // Test 2: Get User
    console.log('📖 Test 2: Get User Profile');
    console.log('Request: GET /users/' + getUserEvent.pathParameters.userId);
    const getResult = await handler(getUserEvent);
    console.log('Response Status:', getResult.statusCode);
    console.log('Response Body:', JSON.parse(getResult.body));
    console.log('');
    
  } catch (error) {
    console.error('❌ Error testing user profile Lambda:', error.message);
  }
}

async function testFoodAnalysisLambda() {
  console.log('\n🧪 Testing Food Analysis Lambda Function\n');
  console.log('═══════════════════════════════════════════════\n');
  
  try {
    // Import the Lambda handler
    const { handler } = require('../food-analysis/index.js');
    
    // Test: Create Food Analysis
    console.log('📝 Test: Create Food Analysis');
    console.log('Request:', JSON.stringify(JSON.parse(createFoodAnalysisEvent.body), null, 2));
    const result = await handler(createFoodAnalysisEvent);
    console.log('Response Status:', result.statusCode);
    console.log('Response Body:', JSON.parse(result.body));
    console.log('');
    
  } catch (error) {
    console.error('❌ Error testing food analysis Lambda:', error.message);
  }
}

async function runTests() {
  console.log('\n🚀 Starting Local Lambda Tests\n');
  console.log('═══════════════════════════════════════════════\n');
  
  await testUserProfileLambda();
  await testFoodAnalysisLambda();
  
  console.log('═══════════════════════════════════════════════');
  console.log('\n✅ Local Lambda tests complete!\n');
  console.log('💡 To test against real API Gateway, run: ./test-api.sh');
  console.log('💡 To check database contents, run: node check-database.js\n');
  
  process.exit(0);
}

// Run the tests
runTests();

