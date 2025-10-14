// Test different field names for FCM token
const https = require('https');

const API_BASE_URL = 'https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod';
const TEST_USER_ID = 'ybJK3XmSewe2n6xEuT1ZfaCIXOL2';
const TEST_EMAIL = 'mohsen.unige2023@gmail.com';
const TEST_FCM_TOKEN = 'field-test-token-' + Date.now();

console.log('🧪 Testing Different Field Names for FCM Token');
console.log('==============================================');
console.log(`User ID: ${TEST_USER_ID}`);
console.log(`Email: ${TEST_EMAIL}`);
console.log(`FCM Token: ${TEST_FCM_TOKEN}`);
console.log('');

// Test with different field names
const testCases = [
  { name: 'fcmToken (camelCase)', data: { userId: TEST_USER_ID, email: TEST_EMAIL, fcmToken: TEST_FCM_TOKEN } },
  { name: 'fcm_token (snake_case)', data: { userId: TEST_USER_ID, email: TEST_EMAIL, fcm_token: TEST_FCM_TOKEN } },
  { name: 'FCMToken (PascalCase)', data: { userId: TEST_USER_ID, email: TEST_EMAIL, FCMToken: TEST_FCM_TOKEN } },
  { name: 'fcm_token (with other fields)', data: { 
    userId: TEST_USER_ID, 
    email: TEST_EMAIL, 
    fcmToken: TEST_FCM_TOKEN,
    displayName: 'Test User',
    themePreference: 'dark'
  }}
];

let currentTest = 0;

function runTest() {
  if (currentTest >= testCases.length) {
    console.log('✅ All tests completed');
    return;
  }

  const testCase = testCases[currentTest];
  console.log(`\n📝 Test ${currentTest + 1}: ${testCase.name}`);
  console.log('Data:', JSON.stringify(testCase.data, null, 2));
  
  const postData = JSON.stringify(testCase.data);

  const options = {
    hostname: 'xpdvcgcji6.execute-api.us-east-1.amazonaws.com',
    port: 443,
    path: '/prod/users',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  const req = https.request(options, (res) => {
    let responseBody = '';
    res.on('data', (chunk) => {
      responseBody += chunk;
    });

    res.on('end', () => {
      console.log(`📥 Response Status: ${res.statusCode}`);
      try {
        const parsedResponse = JSON.parse(responseBody);
        console.log('📥 Response:', JSON.stringify(parsedResponse, null, 2));
        
        if (res.statusCode === 200) {
          console.log('✅ API call successful');
          // Check database
          checkDatabase(testCase.name);
        } else {
          console.log('❌ API call failed');
          currentTest++;
          setTimeout(runTest, 1000);
        }
      } catch (e) {
        console.log('Raw response:', responseBody);
        currentTest++;
        setTimeout(runTest, 1000);
      }
    });
  });

  req.on('error', (e) => {
    console.error('❌ Request error:', e.message);
    currentTest++;
    setTimeout(runTest, 1000);
  });

  req.write(postData);
  req.end();
}

function checkDatabase(testName) {
  console.log(`\n🔍 Checking database for ${testName}...`);
  
  const { exec } = require('child_process');
  exec('node database-manager.js query "SELECT user_id, email, fcm_token FROM users WHERE user_id = \'' + TEST_USER_ID + '\'"', (error, stdout, stderr) => {
    if (error) {
      console.error('❌ Database check error:', error);
    } else {
      console.log(stdout);
      
      if (stdout.includes(TEST_FCM_TOKEN)) {
        console.log(`✅ FCM token was updated with ${testName}!`);
        console.log('🎉 Found the working field name!');
        return;
      } else {
        console.log(`❌ FCM token was NOT updated with ${testName}`);
      }
    }
    
    currentTest++;
    setTimeout(runTest, 2000);
  });
}

// Start the tests
runTest();
