// Test updating displayName to verify Lambda function is working
const https = require('https');

const API_BASE_URL = 'https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod';
const TEST_USER_ID = 'ybJK3XmSewe2n6xEuT1ZfaCIXOL2';
const TEST_EMAIL = 'mohsen.unige2023@gmail.com';
const TEST_DISPLAY_NAME = 'Test Display Name ' + Date.now();

console.log('🧪 Testing Display Name Update');
console.log('==============================');
console.log(`User ID: ${TEST_USER_ID}`);
console.log(`Email: ${TEST_EMAIL}`);
console.log(`Display Name: ${TEST_DISPLAY_NAME}`);
console.log('');

// Test data
const testData = {
  userId: TEST_USER_ID,
  email: TEST_EMAIL,
  displayName: TEST_DISPLAY_NAME
};

console.log('📤 Sending data:');
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
        console.log('Now checking if displayName was updated...');
        
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
  console.log('🔍 Checking database for updated displayName...');
  
  const { exec } = require('child_process');
  exec('node database-manager.js query "SELECT user_id, email, display_name FROM users WHERE user_id = \'' + TEST_USER_ID + '\'"', (error, stdout, stderr) => {
    if (error) {
      console.error('❌ Database check error:', error);
      return;
    }
    
    console.log(stdout);
    
    if (stdout.includes(TEST_DISPLAY_NAME)) {
      console.log('✅ Display name was updated in database!');
      console.log('This means the Lambda function is working correctly');
      console.log('The issue is specifically with the fcmToken field');
    } else {
      console.log('❌ Display name was NOT updated in database');
      console.log('This suggests there might be an issue with the Lambda function deployment');
    }
  });
}
