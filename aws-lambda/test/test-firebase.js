// test/test-firebase.js
// Firebase Admin SDK Test Script
// Tests Firebase initialization and FCM functionality

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const { initializeFirebase, resetFirebase } = require('../firebase-admin');
const { sendToDevice, validateToken, sendToMultipleDevices } = require('../notification-helpers');

// ANSI color codes for better output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[36m',
  bold: '\x1b[1m'
};

function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function success(message) {
  log(`✓ ${message}`, colors.green);
}

function error(message) {
  log(`✗ ${message}`, colors.red);
}

function info(message) {
  log(`ℹ ${message}`, colors.blue);
}

function section(message) {
  log(`\n${'='.repeat(60)}`, colors.bold);
  log(message, colors.bold);
  log('='.repeat(60), colors.bold);
}

/**
 * Test 1: Firebase Initialization
 */
async function testFirebaseInitialization() {
  section('TEST 1: Firebase Admin SDK Initialization');

  try {
    log('\nInitializing Firebase Admin SDK...');
    const app = initializeFirebase();

    if (app) {
      success('Firebase Admin SDK initialized successfully');
      return true;
    } else {
      error('Firebase initialization returned null');
      return false;
    }
  } catch (err) {
    error(`Firebase initialization failed: ${err.message}`);
    return false;
  }
}

/**
 * Test 2: Token Validation (with dummy token)
 */
async function testTokenValidation() {
  section('TEST 2: Token Validation');

  try {
    const dummyToken = 'dummy-token-for-testing-12345';
    log(`\nTesting token validation with dummy token...`);

    const isValid = await validateToken(dummyToken);

    if (!isValid) {
      success('Token validation working correctly (dummy token rejected as expected)');
      return true;
    } else {
      error('Token validation returned true for dummy token (unexpected)');
      return false;
    }
  } catch (err) {
    // For dummy tokens, we might get errors - check if they're expected
    if (err.code === 'messaging/invalid-argument') {
      success('Token validation working correctly (invalid token format detected)');
      return true;
    }
    error(`Token validation test failed: ${err.message}`);
    return false;
  }
}

/**
 * Test 3: Send to Device (with dummy token)
 */
async function testSendToDevice() {
  section('TEST 3: Send to Device');

  try {
    const dummyToken = 'dummy-token-for-testing-12345';
    log(`\nAttempting to send notification to dummy token...`);

    await sendToDevice(
      dummyToken,
      {
        title: 'Test Notification',
        body: 'This is a test notification from Foody'
      },
      {
        test: 'true',
        timestamp: new Date().toISOString(),
        action: 'test_action'
      }
    );

    error('Notification sent to dummy token (unexpected - should have failed)');
    return false;

  } catch (err) {
    if (err.message === 'INVALID_TOKEN' ||
        err.code === 'messaging/invalid-argument' ||
        err.code === 'messaging/invalid-registration-token') {
      success('Send to device working correctly (dummy token rejected as expected)');
      return true;
    }
    error(`Send to device test failed with unexpected error: ${err.message}`);
    return false;
  }
}

/**
 * Test 4: Send to Multiple Devices (with dummy tokens)
 */
async function testSendToMultipleDevices() {
  section('TEST 4: Send to Multiple Devices');

  try {
    const dummyTokens = [
      'dummy-token-1',
      'dummy-token-2',
      'dummy-token-3'
    ];

    log(`\nAttempting to send notification to ${dummyTokens.length} dummy tokens...`);

    const result = await sendToMultipleDevices(
      dummyTokens,
      {
        title: 'Batch Test Notification',
        body: 'This is a batch test notification'
      },
      {
        test: 'true',
        batch: 'true'
      }
    );

    log(`\nBatch Results:`);
    log(`  Success: ${result.successCount}`);
    log(`  Failure: ${result.failureCount}`);
    log(`  Invalid tokens: ${result.invalidTokens.length}`);

    if (result.failureCount === dummyTokens.length) {
      success('Batch send working correctly (all dummy tokens rejected as expected)');
      return true;
    } else {
      error(`Unexpected result - expected all failures, got ${result.failureCount} failures`);
      return false;
    }

  } catch (err) {
    error(`Batch send test failed: ${err.message}`);
    return false;
  }
}

/**
 * Test 5: Send with Real Token (optional, requires user input)
 */
async function testSendWithRealToken() {
  section('TEST 5: Send with Real Token (Optional)');

  // Check if a real token is provided via environment variable
  const realToken = process.env.TEST_FCM_TOKEN;

  if (!realToken) {
    info('No real FCM token provided (set TEST_FCM_TOKEN to test with real device)');
    info('Skipping real token test...');
    return true;
  }

  try {
    log(`\nSending notification to real device...`);
    log(`Token: ${realToken.substring(0, 20)}...`);

    const messageId = await sendToDevice(
      realToken,
      {
        title: 'Foody Test Notification',
        body: 'If you received this, Firebase is working perfectly! 🎉'
      },
      {
        test: 'true',
        timestamp: new Date().toISOString(),
        source: 'firebase-test-script'
      }
    );

    success(`Notification sent successfully! Message ID: ${messageId}`);
    success('Check your device to confirm receipt');
    return true;

  } catch (err) {
    error(`Failed to send to real device: ${err.message}`);
    return false;
  }
}

/**
 * Main test runner
 */
async function runAllTests() {
  log(`${colors.bold}${colors.blue}
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Firebase Admin SDK Test Suite - Foody                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
${colors.reset}`);

  const results = {
    passed: 0,
    failed: 0,
    total: 0
  };

  // Run all tests
  const tests = [
    { name: 'Firebase Initialization', fn: testFirebaseInitialization },
    { name: 'Token Validation', fn: testTokenValidation },
    { name: 'Send to Device', fn: testSendToDevice },
    { name: 'Send to Multiple Devices', fn: testSendToMultipleDevices },
    { name: 'Send with Real Token', fn: testSendWithRealToken }
  ];

  for (const test of tests) {
    results.total++;
    try {
      const passed = await test.fn();
      if (passed) {
        results.passed++;
      } else {
        results.failed++;
      }
    } catch (err) {
      error(`Test "${test.name}" threw an exception: ${err.message}`);
      results.failed++;
    }

    // Small delay between tests
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  // Print summary
  section('TEST SUMMARY');
  log(`\nTotal Tests: ${results.total}`);
  success(`Passed: ${results.passed}`);
  if (results.failed > 0) {
    error(`Failed: ${results.failed}`);
  } else {
    log(`${colors.green}Failed: ${results.failed}${colors.reset}`);
  }

  const successRate = ((results.passed / results.total) * 100).toFixed(1);
  log(`\nSuccess Rate: ${successRate}%`);

  // Final verdict
  if (results.failed === 0) {
    log(`\n${colors.green}${colors.bold}🎉 ALL TESTS PASSED! 🎉${colors.reset}`);
    log(`${colors.green}Firebase Admin SDK is properly configured and ready to use.${colors.reset}`);

    log(`\n${colors.blue}Next Steps:${colors.reset}`);
    log('1. Get a real FCM token from your Flutter app');
    log('2. Set TEST_FCM_TOKEN environment variable in .env');
    log('3. Run this test again to send to a real device');
    log('4. Proceed with Issue #4 (Lambda Function - Send Notification Endpoint)');

    process.exit(0);
  } else {
    log(`\n${colors.red}${colors.bold}❌ SOME TESTS FAILED${colors.reset}`);
    log(`${colors.yellow}Please check the errors above and fix the configuration.${colors.reset}`);

    log(`\n${colors.blue}Troubleshooting:${colors.reset}`);
    log('1. Verify firebase-service-account.json exists and is valid');
    log('2. Check that .env file has FIREBASE_SERVICE_ACCOUNT_PATH set correctly');
    log('3. Ensure Firebase project has FCM enabled');
    log('4. Check Firebase Console for any project issues');

    process.exit(1);
  }
}

// Run the tests
runAllTests().catch(err => {
  error(`\nFatal error running tests: ${err.message}`);
  console.error(err);
  process.exit(1);
});
