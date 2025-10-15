// test-local.js
// Local testing script for send-notification Lambda function

require('dotenv').config({ path: '../.env' });
const handler = require('./index').handler;

/**
 * Test scenarios for send-notification Lambda
 */

// Test 1: Send to all users
async function testSendToAll() {
  console.log('\n=== TEST 1: Send to All Users ===\n');

  const event = {
    httpMethod: 'POST',
    body: JSON.stringify({
      filter: {
        type: 'all'
      },
      notification: {
        title: 'Welcome to Foody!',
        body: 'Start tracking your nutrition today'
      },
      data: {
        screen: '/home',
        type: 'general'
      },
      options: {
        badge: 1
      }
    })
  };

  const result = await handler(event);
  console.log('Result:', JSON.parse(result.body));
}

// Test 2: Send to premium users
async function testSendToPremium() {
  console.log('\n=== TEST 2: Send to Premium Users ===\n');

  const event = {
    httpMethod: 'POST',
    body: JSON.stringify({
      filter: {
        type: 'premium'
      },
      notification: {
        title: 'Premium Feature Alert!',
        body: 'Check out our new premium features'
      },
      data: {
        screen: '/premium',
        type: 'premium_feature'
      }
    })
  };

  const result = await handler(event);
  console.log('Result:', JSON.parse(result.body));
}

// Test 3: Send to age group
async function testSendToAgeGroup() {
  console.log('\n=== TEST 3: Send to Age Group (18-30) ===\n');

  const event = {
    httpMethod: 'POST',
    body: JSON.stringify({
      filter: {
        type: 'age',
        minAge: 18,
        maxAge: 30
      },
      notification: {
        title: 'Special Offer',
        body: 'Get 20% off for young adults!'
      },
      data: {
        screen: '/offers',
        type: 'promotion'
      }
    })
  };

  const result = await handler(event);
  console.log('Result:', JSON.parse(result.body));
}

// Test 4: Send to specific users
async function testSendToSpecificUsers() {
  console.log('\n=== TEST 4: Send to Specific Users ===\n');

  const event = {
    httpMethod: 'POST',
    body: JSON.stringify({
      filter: {
        type: 'userIds',
        userIds: ['user123', 'user456'] // Replace with actual user IDs
      },
      notification: {
        title: 'Personal Message',
        body: 'This is a targeted notification'
      },
      data: {
        type: 'personal'
      }
    })
  };

  const result = await handler(event);
  console.log('Result:', JSON.parse(result.body));
}

// Test 5: Invalid request
async function testInvalidRequest() {
  console.log('\n=== TEST 5: Invalid Request (Missing Title) ===\n');

  const event = {
    httpMethod: 'POST',
    body: JSON.stringify({
      filter: {
        type: 'all'
      },
      notification: {
        body: 'Missing title'
      }
    })
  };

  const result = await handler(event);
  console.log('Result:', JSON.parse(result.body));
}

// Run tests
async function runTests() {
  try {
    console.log('🧪 Starting send-notification Lambda tests...\n');

    // Uncomment the tests you want to run:

    await testSendToAll();
    // await testSendToPremium();
    // await testSendToAgeGroup();
    // await testSendToSpecificUsers();
    // await testInvalidRequest();

    console.log('\n✅ All tests completed!\n');
    process.exit(0);
  } catch (error) {
    console.error('❌ Test failed:', error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  runTests();
}

module.exports = { runTests };
