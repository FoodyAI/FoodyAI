# 🔔 Firebase Push Notification Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Database Schema](#database-schema)
5. [Backend Setup (AWS Lambda)](#backend-setup-aws-lambda)
6. [Flutter Setup](#flutter-setup)
7. [Sending Notifications](#sending-notifications)
8. [User Filtering](#user-filtering)
9. [Testing](#testing)
10. [Troubleshooting](#troubleshooting)

---

## Overview

This guide explains how to implement Firebase Cloud Messaging (FCM) push notifications in the Foody app with AWS RDS PostgreSQL database integration.

**Features:**
- ✅ Send notifications to all users
- ✅ Filter by premium users
- ✅ Filter by age groups
- ✅ Filter by notification preferences
- ✅ Schedule campaigns
- ✅ Track notification history
- ✅ User preference management

---

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (FCM Client)   │
└────────┬────────┘
         │
         │ 1. Register FCM Token
         │
         ▼
┌─────────────────────┐
│   AWS Lambda        │
│  (User Profile)     │
│  Store FCM Token    │
└────────┬────────────┘
         │
         │ 2. Save to DB
         │
         ▼
┌─────────────────────┐
│  PostgreSQL RDS     │
│  (users table with  │
│   fcm_token)        │
└─────────────────────┘

┌─────────────────────┐
│  Admin/Backend      │
│  (Send Notification)│
└────────┬────────────┘
         │
         │ 3. Query filtered users
         │
         ▼
┌─────────────────────┐
│   AWS Lambda        │
│ (Send Notification) │
│  + Firebase Admin   │
└────────┬────────────┘
         │
         │ 4. Send FCM message
         │
         ▼
┌─────────────────────┐
│  Firebase Cloud     │
│    Messaging        │
└────────┬────────────┘
         │
         │ 5. Deliver to device
         │
         ▼
┌─────────────────────┐
│   User's Device     │
│  (Receives Push)    │
└─────────────────────┘
```

---

## Prerequisites

### Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your Foody project
3. Navigate to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Download the JSON file (keep it secure!)

### Required Packages
```yaml
# pubspec.yaml (Flutter)
dependencies:
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.0.0

# package.json (AWS Lambda)
{
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "pg": "^8.11.0"
  }
}
```

---

## Database Schema

### Step 1: Update Users Table

Run this SQL on your PostgreSQL RDS database:

```sql
-- Add FCM token and notification preferences
ALTER TABLE users
ADD COLUMN IF NOT EXISTS fcm_token TEXT,
ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS last_token_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT false;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_users_fcm_token
ON users(fcm_token) WHERE fcm_token IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_notifications_enabled
ON users(notifications_enabled);
```

### Step 2: Create Notifications Log Table

```sql
-- Track all sent notifications
CREATE TABLE IF NOT EXISTS notifications_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255),
    notification_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'sent',
    error_message TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_notifications_log_user_id
ON notifications_log(user_id);

CREATE INDEX IF NOT EXISTS idx_notifications_log_sent_at
ON notifications_log(sent_at);
```

### Step 3: Create Campaigns Table

```sql
-- Manage notification campaigns
CREATE TABLE IF NOT EXISTS notification_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_name VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    filter_criteria JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'draft',
    total_recipients INTEGER DEFAULT 0,
    successful_sends INTEGER DEFAULT 0,
    failed_sends INTEGER DEFAULT 0
);
```

---

## Backend Setup (AWS Lambda)

### Step 1: Create Send Notification Lambda

**File:** `aws-lambda/send-notification/index.js`

```javascript
const admin = require('firebase-admin');
const { Pool } = require('pg');

// Initialize Firebase Admin SDK
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Initialize PostgreSQL connection
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false }
});

exports.handler = async (event) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'POST,OPTIONS'
  };

  try {
    // Handle CORS preflight
    if (event.httpMethod === 'OPTIONS') {
      return { statusCode: 200, headers, body: JSON.stringify({ message: 'OK' }) };
    }

    const { title, body, data, filter } = JSON.parse(event.body);

    console.log('📤 Send Notification Request:', { title, body, filter });

    // Get filtered users with FCM tokens
    const users = await getFilteredUsers(filter);

    if (users.length === 0) {
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          success: true,
          message: 'No users match the filter criteria',
          sent: 0
        })
      };
    }

    console.log(`📋 Found ${users.length} users matching filter`);

    // Send notifications
    const results = await sendNotifications(users, title, body, data);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        success: true,
        sent: results.successful,
        failed: results.failed,
        total: users.length
      })
    };
  } catch (error) {
    console.error('❌ Error sending notifications:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        success: false,
        error: error.message
      })
    };
  }
};

// Get filtered users based on criteria
async function getFilteredUsers(filter) {
  let query = `
    SELECT user_id, email, fcm_token, display_name
    FROM users
    WHERE notifications_enabled = true
      AND fcm_token IS NOT NULL
  `;
  const params = [];

  if (!filter || filter.type === 'all') {
    // Send to all users with notifications enabled
  } else if (filter.type === 'premium') {
    query += ' AND is_premium = true';
  } else if (filter.type === 'age') {
    if (filter.operator === '<') {
      query += ` AND age < $1`;
      params.push(filter.value);
    } else if (filter.operator === '>') {
      query += ` AND age > $1`;
      params.push(filter.value);
    } else if (filter.operator === 'between') {
      query += ` AND age BETWEEN $1 AND $2`;
      params.push(filter.min, filter.max);
    }
  } else if (filter.type === 'userIds') {
    query += ` AND user_id = ANY($1)`;
    params.push(filter.userIds);
  }

  console.log('🔍 Query:', query);
  console.log('📝 Params:', params);

  const result = await pool.query(query, params);
  return result.rows;
}

// Send notifications to users
async function sendNotifications(users, title, body, data) {
  let successful = 0;
  let failed = 0;

  for (const user of users) {
    try {
      const message = {
        notification: {
          title: title,
          body: body
        },
        data: data || {},
        token: user.fcm_token
      };

      await admin.messaging().send(message);

      // Log successful notification
      await logNotification(user.user_id, title, body, data, 'sent', null);

      successful++;
      console.log(`✅ Sent to ${user.email}`);
    } catch (error) {
      console.error(`❌ Failed to send to ${user.email}:`, error.message);

      // Log failed notification
      await logNotification(user.user_id, title, body, data, 'failed', error.message);

      failed++;
    }
  }

  return { successful, failed };
}

// Log notification to database
async function logNotification(userId, title, body, data, status, errorMessage) {
  try {
    const query = `
      INSERT INTO notifications_log (user_id, notification_type, title, body, data, status, error_message)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
    `;
    await pool.query(query, [
      userId,
      'manual',
      title,
      body,
      JSON.stringify(data || {}),
      status,
      errorMessage
    ]);
  } catch (error) {
    console.error('❌ Error logging notification:', error);
  }
}
```

### Step 2: Deploy Lambda Function

```bash
cd aws-lambda/send-notification

# Install dependencies
npm install firebase-admin pg

# Copy your Firebase service account JSON
cp ~/Downloads/firebase-service-account.json .

# Create deployment package
zip -r send-notification.zip index.js firebase-service-account.json node_modules/

# Deploy to AWS Lambda
aws lambda create-function \
  --function-name foody-send-notification \
  --runtime nodejs18.x \
  --role arn:aws:iam::YOUR_ACCOUNT:role/foody-lambda-role \
  --handler index.handler \
  --zip-file fileb://send-notification.zip \
  --environment Variables="{
    DB_HOST=your-rds-endpoint,
    DB_PORT=5432,
    DB_NAME=foody,
    DB_USER=postgres,
    DB_PASSWORD=your-password
  }" \
  --timeout 60 \
  --memory-size 512
```

### Step 3: Update User Profile Lambda

**File:** `aws-lambda/user-profile/index.js` (Add to existing code)

```javascript
// In the POST handler, add these fields to the INSERT/UPDATE queries

// For new user insertion:
if (userData.fcmToken !== undefined) {
  updateFields.push(`fcm_token = $${paramIndex++}`);
  updateValues.push(userData.fcmToken);
}

if (userData.notificationsEnabled !== undefined) {
  updateFields.push(`notifications_enabled = $${paramIndex++}`);
  updateValues.push(userData.notificationsEnabled);
}

if (userData.isPremium !== undefined) {
  updateFields.push(`is_premium = $${paramIndex++}`);
  updateValues.push(userData.isPremium);
}
```

---

## Flutter Setup

### Step 1: Configure Firebase

**Android:** `android/app/google-services.json` (already exists)
**iOS:** `ios/Runner/GoogleService-Info.plist` (already exists)

### Step 2: Request Permissions (iOS)

**File:** `ios/Runner/Info.plist`

```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

### Step 3: Create Notification Service

**File:** `lib/services/notification_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:foody/services/aws_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AWSService _awsService = AWSService();
  String? _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    print('🔔 Initializing Notification Service...');

    // Request permission (iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional notification permission');
    } else {
      print('❌ User declined notification permission');
      return;
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('📱 FCM Token: $_fcmToken');

    // Send token to backend
    await _sendTokenToBackend();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed: $newToken');
      _fcmToken = newToken;
      _sendTokenToBackend();
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    print('✅ Notification Service initialized');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Send FCM token to AWS backend
  Future<void> _sendTokenToBackend() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _fcmToken == null) {
        print('⚠️ Cannot send token: user or token is null');
        return;
      }

      print('📤 Sending FCM token to backend...');

      await _awsService.updateFCMToken(
        userId: user.uid,
        fcmToken: _fcmToken!,
      );

      print('✅ FCM token sent to backend');
    } catch (e) {
      print('❌ Error sending FCM token: $e');
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message received:');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'foody_channel',
      'Foody Notifications',
      channelDescription: 'Notifications from Foody app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Foody',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification tapped: ${message.data}');

    // Navigate based on notification data
    final data = message.data;
    if (data.containsKey('route')) {
      // TODO: Implement navigation
      // NavigationService.pushNamed(data['route']);
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Local notification tapped: ${response.payload}');
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(bool enabled) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _awsService.updateNotificationPreferences(
        userId: user.uid,
        notificationsEnabled: enabled,
      );

      print('✅ Notification preferences updated: $enabled');
    } catch (e) {
      print('❌ Error updating notification preferences: $e');
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background message received:');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
}
```

### Step 4: Update AWS Service

**File:** `lib/services/aws_service.dart` (Add these methods)

```dart
/// Update FCM token for user
Future<Map<String, dynamic>?> updateFCMToken({
  required String userId,
  required String fcmToken,
}) async {
  try {
    print('📤 Updating FCM token for user: $userId');

    final idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('User not authenticated');
    }

    final response = await _dio.post(
      '/users',
      data: {
        'userId': userId,
        'fcmToken': fcmToken,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('✅ FCM token updated successfully');
      return response.data;
    } else {
      throw Exception('Failed to update FCM token: ${response.statusMessage}');
    }
  } catch (e) {
    print('❌ Error updating FCM token: $e');
    return null;
  }
}

/// Update notification preferences
Future<Map<String, dynamic>?> updateNotificationPreferences({
  required String userId,
  required bool notificationsEnabled,
}) async {
  try {
    print('📤 Updating notification preferences for user: $userId');

    final idToken = await _getIdToken();
    if (idToken == null) {
      throw Exception('User not authenticated');
    }

    final response = await _dio.post(
      '/users',
      data: {
        'userId': userId,
        'notificationsEnabled': notificationsEnabled,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('✅ Notification preferences updated successfully');
      return response.data;
    } else {
      throw Exception('Failed to update notification preferences');
    }
  } catch (e) {
    print('❌ Error updating notification preferences: $e');
    return null;
  }
}
```

### Step 5: Initialize in Main

**File:** `lib/main.dart`

```dart
import 'package:foody/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Add background handler at top level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  print('Firebase initialized successfully!');

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();

  await dotenv.load(fileName: ".env");
  setupServiceLocator();

  final migrationService = MigrationService();
  await migrationService.migrateFromSharedPreferences();

  runApp(const MyApp());
}
```

### Step 6: Add Notification Settings UI

**File:** `lib/presentation/pages/profile_view.dart` (Add to settings section)

```dart
// Add this widget in your profile settings
SwitchListTile(
  title: const Text('Push Notifications'),
  subtitle: const Text('Receive updates and promotional messages'),
  value: notificationsEnabled, // From user profile
  onChanged: (bool value) async {
    setState(() {
      notificationsEnabled = value;
    });

    // Update backend
    await NotificationService().updateNotificationPreferences(value);

    // Update local state
    await userProfileViewModel.updateNotificationPreferences(value);
  },
),
```

---

## Sending Notifications

### Method 1: Using cURL

```bash
# Send to all users
curl -X POST https://your-api-gateway-url/prod/send-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "title": "Welcome to Foody!",
    "body": "Start tracking your nutrition today",
    "data": {
      "route": "/home",
      "action": "open_app"
    },
    "filter": {
      "type": "all"
    }
  }'

# Send to premium users only
curl -X POST https://your-api-gateway-url/prod/send-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "title": "Premium Feature Alert!",
    "body": "Check out our new premium features",
    "filter": {
      "type": "premium"
    }
  }'

# Send to users under 30
curl -X POST https://your-api-gateway-url/prod/send-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "title": "Youth Fitness Challenge!",
    "body": "Join our challenge for users under 30",
    "filter": {
      "type": "age",
      "operator": "<",
      "value": 30
    }
  }'
```

### Method 2: Using Postman

1. Open Postman
2. Create POST request to: `https://your-api-gateway-url/prod/send-notification`
3. Headers:
   - `Content-Type: application/json`
   - `Authorization: Bearer YOUR_ID_TOKEN`
4. Body (raw JSON):
```json
{
  "title": "Test Notification",
  "body": "This is a test message",
  "data": {
    "route": "/home"
  },
  "filter": {
    "type": "all"
  }
}
```

### Method 3: Using AWS Lambda Console

1. Go to AWS Lambda Console
2. Select `foody-send-notification` function
3. Go to **Test** tab
4. Create test event:
```json
{
  "httpMethod": "POST",
  "body": "{\"title\":\"Test\",\"body\":\"Hello World\",\"filter\":{\"type\":\"all\"}}"
}
```
5. Click **Test**

---

## User Filtering

### Filter Types

#### 1. All Users
```json
{
  "filter": {
    "type": "all"
  }
}
```

#### 2. Premium Users Only
```json
{
  "filter": {
    "type": "premium"
  }
}
```

#### 3. Age-Based Filtering

**Users under 30:**
```json
{
  "filter": {
    "type": "age",
    "operator": "<",
    "value": 30
  }
}
```

**Users over 40:**
```json
{
  "filter": {
    "type": "age",
    "operator": ">",
    "value": 40
  }
}
```

**Users between 25-35:**
```json
{
  "filter": {
    "type": "age",
    "operator": "between",
    "min": 25,
    "max": 35
  }
}
```

#### 4. Specific Users
```json
{
  "filter": {
    "type": "userIds",
    "userIds": ["user_id_1", "user_id_2", "user_id_3"]
  }
}
```

---

## Testing

### Test Checklist

- [ ] **Token Registration**
  - User logs in
  - FCM token generated
  - Token sent to backend
  - Token stored in database

- [ ] **Foreground Notification**
  - App is open
  - Send test notification
  - Notification appears

- [ ] **Background Notification**
  - App in background
  - Send test notification
  - Notification appears in tray

- [ ] **Notification Tap**
  - Tap notification
  - App opens to correct screen

- [ ] **Filter: All Users**
  - Send to all users
  - All users receive notification

- [ ] **Filter: Premium Users**
  - Mark user as premium
  - Send to premium only
  - Only premium users receive

- [ ] **Filter: Age < 30**
  - Create users with different ages
  - Send to age < 30
  - Only users under 30 receive

- [ ] **Notification Preferences**
  - Disable notifications
  - Send notification
  - User does NOT receive

- [ ] **Token Refresh**
  - Force token refresh
  - New token sent to backend
  - Can still receive notifications

### Test Script

```bash
#!/bin/bash

API_URL="https://your-api-gateway-url/prod/send-notification"
TOKEN="your_firebase_id_token"

echo "🧪 Testing Notification System..."

# Test 1: Send to all users
echo "📤 Test 1: Send to all users"
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Test: All Users",
    "body": "This should reach everyone",
    "filter": {"type": "all"}
  }'

echo "\n"
sleep 5

# Test 2: Send to premium users
echo "📤 Test 2: Send to premium users"
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Test: Premium Only",
    "body": "Premium users should see this",
    "filter": {"type": "premium"}
  }'

echo "\n"
sleep 5

# Test 3: Send to users under 30
echo "📤 Test 3: Send to age < 30"
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Test: Age < 30",
    "body": "Young users should see this",
    "filter": {"type": "age", "operator": "<", "value": 30}
  }'

echo "\n✅ Tests completed!"
```

---

## Troubleshooting

### Issue: Token not saved to database

**Check:**
1. User is authenticated
2. FCM token is not null
3. Lambda has database permissions
4. Check CloudWatch logs

**Solution:**
```dart
// Force token refresh
await FirebaseMessaging.instance.deleteToken();
await NotificationService().initialize();
```

### Issue: Notifications not received

**Check:**
1. User has granted notification permission
2. FCM token is valid in database
3. `notifications_enabled = true` in database
4. Device has internet connection
5. Firebase project configured correctly

### Issue: Background notifications not working (iOS)

**Check:**
1. `UIBackgroundModes` added to Info.plist
2. App has notification permission
3. Device not in Do Not Disturb mode

### Issue: Lambda function timeout

**Check:**
1. Too many users to notify
2. Increase Lambda timeout to 5 minutes
3. Consider batch processing

**Solution:**
```bash
aws lambda update-function-configuration \
  --function-name foody-send-notification \
  --timeout 300
```

### Issue: Firebase Admin SDK error

**Check:**
1. Service account JSON file is correct
2. Firebase project ID matches
3. Service account has FCM send permission

---

## Best Practices

1. **Rate Limiting**: Don't send too many notifications too quickly
2. **Batch Processing**: Process large user lists in batches
3. **Error Handling**: Always log failed notifications
4. **Token Cleanup**: Remove invalid/expired tokens from database
5. **User Preferences**: Always respect user notification settings
6. **Testing**: Test on both iOS and Android devices
7. **Monitoring**: Monitor CloudWatch logs for errors
8. **Security**: Never expose Firebase service account key

---

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [AWS Lambda Node.js](https://docs.aws.amazon.com/lambda/latest/dg/lambda-nodejs.html)
- [Flutter Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview)

---

## Support

For issues or questions:
- Check CloudWatch logs for Lambda errors
- Check Flutter console logs for client errors
- Review this documentation
- Contact the development team

**Last Updated:** 2025-01-14
**Version:** 1.0.0
