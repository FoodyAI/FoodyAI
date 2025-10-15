// test-validation.js
// Test script to validate Lambda function structure and basic functionality

require('dotenv').config({ path: './.env' });
const handler = require('./index').handler;

/**
 * Test the Lambda function with various scenarios
 * This tests the function structure without requiring database connection
 */

async function testFunctionStructure() {
  console.log('🧪 Testing Lambda Function Structure...\n');

  // Test 1: Invalid HTTP method
  console.log('=== TEST 1: Invalid HTTP Method (GET) ===');
  try {
    const result = await handler({
      httpMethod: 'GET',
      body: '{}'
    });
    console.log('Status Code:', result.statusCode);
    console.log('Response:', JSON.parse(result.body));
  } catch (error) {
    console.log('Error:', error.message);
  }

  // Test 2: Missing required fields
  console.log('\n=== TEST 2: Missing Required Fields ===');
  try {
    const result = await handler({
      httpMethod: 'POST',
      body: JSON.stringify({
        notification: {
          body: 'Missing title'
        }
      })
    });
    console.log('Status Code:', result.statusCode);
    console.log('Response:', JSON.parse(result.body));
  } catch (error) {
    console.log('Error:', error.message);
  }

  // Test 3: Invalid filter type
  console.log('\n=== TEST 3: Invalid Filter Type ===');
  try {
    const result = await handler({
      httpMethod: 'POST',
      body: JSON.stringify({
        filter: {
          type: 'invalid'
        },
        notification: {
          title: 'Test',
          body: 'Test message'
        }
      })
    });
    console.log('Status Code:', result.statusCode);
    console.log('Response:', JSON.parse(result.body));
  } catch (error) {
    console.log('Error:', error.message);
  }

  // Test 4: Valid request structure (will fail at database connection)
  console.log('\n=== TEST 4: Valid Request Structure ===');
  try {
    const result = await handler({
      httpMethod: 'POST',
      body: JSON.stringify({
        filter: {
          type: 'all'
        },
        notification: {
          title: 'Test Notification',
          body: 'This is a test message'
        },
        data: {
          screen: '/home',
          type: 'test'
        }
      })
    });
    console.log('Status Code:', result.statusCode);
    console.log('Response:', JSON.parse(result.body));
  } catch (error) {
    console.log('Expected Error (Database Connection):', error.message);
  }

  console.log('\n✅ Function structure tests completed!');
}

// Run tests
testFunctionStructure().catch(console.error);
