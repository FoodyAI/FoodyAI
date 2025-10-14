// Test FCM Token Update via API Gateway
const https = require('https');

const API_BASE_URL = 'https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod';
const TEST_USER_ID = 'ybJK3XmSewe2n6xEuT1ZfaCIXOL2';
const TEST_EMAIL = 'mohsen.unige2023@gmail.com';
const TEST_FCM_TOKEN = 'test-fcm-token-from-api-' + Date.now();

console.log('🧪 Testing FCM Token Update via API Gateway');
console.log('==========================================');
console.log(`User ID: ${TEST_USER_ID}`);
console.log(`Email: ${TEST_EMAIL}`);
console.log(`FCM Token: ${TEST_FCM_TOKEN}`);
console.log('');

// Test data
const testData = {
  userId: TEST_USER_ID,
  email: TEST_EMAIL,
  fcmToken: TEST_FCM_TOKEN
};

const postData = JSON.stringify(testData);

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

console.log('📤 Sending request to API Gateway...');
console.log('Request data:', testData);
console.log('');

const req = https.request(options, (res) => {
  console.log(`📥 Response Status: ${res.statusCode}`);
  console.log(`📥 Response Headers:`, res.headers);
  console.log('');

  let responseBody = '';
  res.on('data', (chunk) => {
    responseBody += chunk;
  });

  res.on('end', () => {
    console.log('📥 Response Body:');
    try {
      const parsedResponse = JSON.parse(responseBody);
      console.log(JSON.stringify(parsedResponse, null, 2));
      
      if (res.statusCode === 200 && parsedResponse.success) {
        console.log('');
        console.log('✅ FCM token update successful!');
        console.log('Now checking database to verify...');
        
        // Check database
        setTimeout(() => {
          checkDatabase();
        }, 2000);
      } else {
        console.log('');
        console.log('❌ FCM token update failed');
        console.log(`Status: ${res.statusCode}`);
        console.log(`Success: ${parsedResponse.success}`);
        if (parsedResponse.error) {
          console.log(`Error: ${parsedResponse.error}`);
        }
      }
    } catch (e) {
      console.log('Raw response:', responseBody);
      console.log('❌ Failed to parse response as JSON');
    }
  });
});

req.on('error', (e) => {
  console.error('❌ Request error:', e.message);
});

req.write(postData);
req.end();

function checkDatabase() {
  console.log('');
  console.log('🔍 Checking database for updated FCM token...');
  
  const { exec } = require('child_process');
  exec('node database-manager.js query "SELECT user_id, email, fcm_token FROM users WHERE user_id = \'' + TEST_USER_ID + '\'"', (error, stdout, stderr) => {
    if (error) {
      console.error('❌ Database check error:', error);
      return;
    }
    
    console.log(stdout);
    
    if (stdout.includes(TEST_FCM_TOKEN)) {
      console.log('✅ FCM token successfully updated in database!');
    } else {
      console.log('❌ FCM token not found in database');
    }
  });
}
