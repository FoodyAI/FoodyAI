# Firebase Cloud Messaging (FCM) Implementation

## Overview
This document describes the FCM implementation for push notifications in the Foody Flutter application.

## Architecture

### 1. NotificationService (`lib/services/notification_service.dart`)
Singleton service that manages all FCM operations:

#### Key Features:
- **Token Management**: Retrieves, stores, and refreshes FCM tokens
- **Permission Handling**: Requests and manages notification permissions (iOS & Android)
- **Message Handlers**: Processes notifications in foreground, background, and terminated states
- **Local Notifications**: Displays notifications when app is in foreground
- **Navigation**: Routes users to appropriate screens based on notification data

#### Public Methods:
```dart
// Initialize the service (call after user signs in)
await NotificationService().initialize(userId: 'user123');

// Get current FCM token
String? token = NotificationService().currentToken;

// Get stored token from local storage
String? storedToken = await NotificationService().getStoredToken();

// Check if notifications are enabled
bool enabled = await NotificationService().areNotificationsEnabled();

// Request permissions (useful for settings screen)
bool granted = await NotificationService().requestPermissionsAgain();

// Update notification preferences on backend
bool success = await NotificationService().updateNotificationPreferences(
  userId: 'user123',
  notificationsEnabled: true,
);

// Delete token (call on sign out)
await NotificationService().deleteToken();
```

### 2. Integration Points

#### main.dart
- Background message handler is registered at app startup
- Must be done before `runApp()` is called

```dart
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```

#### auth_viewmodel.dart
- **Sign In**: Initializes NotificationService after successful authentication
- **Sign Out**: Deletes FCM token before signing out
- **Account Deletion**: Deletes FCM token before account deletion

### 3. Backend Integration (AWS)

#### API Endpoints:
1. **Update FCM Token** - `POST /users`
   - Saves/updates the FCM token for a user
   - Payload: `{ userId, fcmToken }`

2. **Update Notification Preferences** - `POST /users`
   - Updates user's notification settings
   - Payload: `{ userId, notificationsEnabled }`

### 4. Notification Flow

#### Foreground (App is open):
1. `FirebaseMessaging.onMessage` receives the message
2. `_handleForegroundMessage()` processes it
3. `_showLocalNotification()` displays it using flutter_local_notifications
4. User taps → `_onNotificationTap()` → `_handleNotificationNavigation()`

#### Background (App in background):
1. System displays the notification automatically
2. User taps → `FirebaseMessaging.onMessageOpenedApp` fires
3. `_handleMessageOpenedApp()` → `_handleNotificationNavigation()`

#### Terminated (App not running):
1. System displays the notification automatically
2. User taps → App launches
3. `getInitialMessage()` retrieves the notification
4. `_handleInitialMessage()` → `_handleNotificationNavigation()`

#### Background Handler (Isolated):
1. `firebaseMessagingBackgroundHandler()` runs in separate isolate
2. Only used for data processing, not for displaying notifications
3. Must be a top-level function

### 5. Notification Data Structure

Notifications should follow this structure:

```json
{
  "notification": {
    "title": "Meal Reminder",
    "body": "Don't forget to log your lunch!"
  },
  "data": {
    "type": "food_reminder",
    "screen": "/home",
    "foodId": "abc123"
  }
}
```

#### Navigation Types:
- `type: "food_reminder"` → Navigate to home screen
- `type: "profile_update"` → Navigate to profile screen
- `screen: "/specific-route"` → Navigate to specified route

### 6. Platform Configuration

#### iOS (ios/Runner/Info.plist)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />

<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

### 7. Testing

#### Manual Testing:
1. **Get FCM Token**: Sign in and check console logs for token
2. **Send Test Notification**: Use Firebase Console → Cloud Messaging → Send test message
3. **Test Foreground**: Send notification while app is open
4. **Test Background**: Minimize app and send notification
5. **Test Terminated**: Force close app and send notification
6. **Test Navigation**: Include data payload and verify navigation works

#### Firebase Console Testing:
1. Go to Firebase Console → Project → Cloud Messaging
2. Click "Send your first message"
3. Enter title and body
4. Click "Send test message"
5. Enter your FCM token
6. Click "Test"

#### Backend Testing:
Use the Lambda function to send notifications:
```bash
# From lambda/src/sendPushNotification.js
# POST to the endpoint with:
{
  "userId": "user123",
  "title": "Test Title",
  "body": "Test Body",
  "data": {
    "type": "food_reminder",
    "screen": "/home"
  }
}
```

### 8. Troubleshooting

#### No Token Received:
- Verify Firebase is initialized in main.dart
- Check that google-services.json (Android) and GoogleService-Info.plist (iOS) are present
- Ensure permissions are granted
- Check console logs for errors

#### Notifications Not Displayed:
- **iOS**: Verify Info.plist has background modes
- **Android**: Verify AndroidManifest.xml has service and permissions
- Check notification permissions in device settings
- Verify notification channel is created (Android)

#### Background Handler Not Working:
- Ensure handler is top-level function with @pragma annotation
- Verify it's registered before runApp() in main.dart
- Check that app has background refresh enabled (iOS Settings)

#### Token Not Sent to Backend:
- Check network connectivity
- Verify AWS Lambda endpoint is correct
- Check Firebase Auth token is valid
- Review console logs for error messages

### 9. Security Considerations

1. **Token Storage**: FCM tokens are stored locally using SharedPreferences
2. **Token Refresh**: Service automatically handles token refresh
3. **Authentication**: All backend requests require Firebase Auth token
4. **Token Cleanup**: Tokens are deleted on sign out and account deletion

### 10. Future Enhancements

- Add notification categories for better organization
- Implement notification badges for unread counts
- Add rich notifications with images
- Support notification actions (reply, dismiss, etc.)
- Add notification scheduling
- Implement notification analytics

## Dependencies

```yaml
firebase_core: ^2.24.0
firebase_messaging: ^14.7.0
flutter_local_notifications: ^16.3.0
shared_preferences: ^2.2.2
```

## References

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Messaging Plugin](https://firebase.flutter.dev/docs/messaging/overview)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
