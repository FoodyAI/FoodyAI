// Test FCM token with detailed debugging
const https = require('https');

const API_BASE_URL = 'https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod';
const TEST_USER_ID = 'ybJK3XmSewe2n6xEuT1ZfaCIXOL2';
const TEST_EMAIL = 'mohsen.unige2023@gmail.com';
const TEST_FCM_TOKEN = 'debug-fcm-token-' + Date.now();

console.log('🔍 Debug FCM Token Processing');
console.log('=============================');
console.log(`User ID: ${TEST_USER_ID}`);
console.log(`Email: ${TEST_EMAIL}`);
console.log(`FCM Token: ${TEST_FCM_TOKEN}`);
console.log('');

// Test with multiple fields to see which ones work
const testData = {
  userId: TEST_USER_ID,
  email: TEST_EMAIL,
  displayName: 'Debug Test User ' + Date.now(),
  fcmToken: TEST_FCM_TOKEN,
  themePreference: 'light',
  notificationsEnabled: true
};

console.log('📤 Sending data with multiple fields:');
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
        console.log('Now checking which fields were updated...');
        
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
  console.log('🔍 Checking database for all updated fields...');
  
  const { exec } = require('child_process');
  exec('node database-manager.js query "SELECT user_id, email, display_name, fcm_token, theme_preference, notifications_enabled FROM users WHERE user_id = \'' + TEST_USER_ID + '\'"', (error, stdout, stderr) => {
    if (error) {
      console.error('❌ Database check error:', error);
      return;
    }
    
    console.log(stdout);
    
    // Check each field
    const checks = [
      { field: 'displayName', value: testData.displayName, dbField: 'display_name' },
      { field: 'fcmToken', value: testData.fcmToken, dbField: 'fcm_token' },
      { field: 'themePreference', value: testData.themePreference, dbField: 'theme_preference' },
      { field: 'notificationsEnabled', value: testData.notificationsEnabled, dbField: 'notifications_enabled' }
    ];
    
    console.log('\n📊 Field Update Results:');
    checks.forEach(check => {
      if (stdout.includes(check.value)) {
        console.log(`✅ ${check.field} (${check.dbField}) was updated`);
      } else {
        console.log(`❌ ${check.field} (${check.dbField}) was NOT updated`);
      }
    });
    
    console.log('\n💡 This will help identify which fields are being processed correctly');
  });
}
