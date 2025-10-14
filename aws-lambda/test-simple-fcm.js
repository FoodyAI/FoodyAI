// Test simple FCM token update
const https = require('https');

const API_BASE_URL = 'https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod';
const TEST_USER_ID = 'ybJK3XmSewe2n6xEuT1ZfaCIXOL2';
const TEST_EMAIL = 'mohsen.unige2023@gmail.com';

console.log('🧪 Testing Simple FCM Token Update');
console.log('==================================');
console.log(`User ID: ${TEST_USER_ID}`);
console.log(`Email: ${TEST_EMAIL}`);
console.log('');

// Test with just the essential fields plus fcmToken
const testData = {
  userId: TEST_USER_ID,
  email: TEST_EMAIL,
  fcmToken: 'simple-test-token-123'
};

console.log('📤 Sending minimal data with fcmToken:');
console.log(JSON.stringify(testData, null, 2));
console.log('');

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

const req = https.request(options, (res) => {
  console.log(`📥 Response Status: ${res.statusCode}`);
  
  let responseBody = '';
  res.on('data', (chunk) => {
    responseBody += chunk;
  });

  res.on('end', () => {
    console.log('📥 Response Body:');
    try {
      const parsedResponse = JSON.parse(responseBody);
      console.log(JSON.stringify(parsedResponse, null, 2));
      
      if (res.statusCode === 200) {
        console.log('');
        console.log('✅ API call successful');
        console.log('Checking if fcmToken was updated...');
        
        // Check database
        checkDatabase();
      } else {
        console.log('');
        console.log('❌ API call failed');
      }
    } catch (e) {
      console.log('Raw response:', responseBody);
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
  console.log('🔍 Checking database for fcmToken...');
  
  const { exec } = require('child_process');
  exec('node database-manager.js query "SELECT user_id, email, fcm_token FROM users WHERE user_id = \'' + TEST_USER_ID + '\'"', (error, stdout, stderr) => {
    if (error) {
      console.error('❌ Database check error:', error);
      return;
    }
    
    console.log(stdout);
    
    if (stdout.includes('simple-test-token-123')) {
      console.log('✅ FCM token was updated!');
    } else {
      console.log('❌ FCM token was NOT updated');
      console.log('');
      console.log('🔍 Let me check if there\'s a JavaScript error in the Lambda function...');
      console.log('The issue might be:');
      console.log('1. JavaScript syntax error in the Lambda function');
      console.log('2. Field name mismatch');
      console.log('3. Lambda function not deployed with latest code');
      console.log('4. Database constraint issue');
    }
  });
}
