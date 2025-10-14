# FCM Testing Guide

## Pre-Testing Checklist

Before testing FCM functionality, ensure:

- [ ] Firebase project is set up and configured
- [ ] `google-services.json` (Android) is in `android/app/`
- [ ] `GoogleService-Info.plist` (iOS) is in `ios/Runner/`
- [ ] App has been built at least once on the target device
- [ ] Device/simulator has internet connectivity

## Test 1: FCM Token Retrieval

**Objective**: Verify that the app can retrieve and store FCM token

**Steps**:
1. Launch the app
2. Sign in with a test account
3. Check the console logs for:
   ```
   🔔 AuthViewModel: Initializing notification service...
   🔄 NotificationService: Initializing...
   🔄 NotificationService: Getting FCM token...
   ✅ NotificationService: FCM token received
   📝 NotificationService: Token: [YOUR_TOKEN_HERE]
   ```
4. Copy the FCM token from the logs

**Expected Result**:
- Token is successfully retrieved and logged
- Token is sent to AWS backend
- No error messages in console

**Troubleshooting**:
- If no token: Check Firebase configuration files
- If "User not authenticated": Verify sign-in was successful
- If network error: Check AWS Lambda endpoint

---

## Test 2: Foreground Notifications

**Objective**: Verify notifications display when app is open

**Steps**:
1. Keep the app open and in the foreground
2. Send a test notification using Firebase Console:
   - Go to Firebase Console → Cloud Messaging → Send test message
   - Enter notification title: "Test Foreground"
   - Enter notification body: "This is a foreground test"
   - Paste your FCM token
   - Click "Test"
3. Observe the app

**Expected Result**:
- Notification appears as a local notification (banner/popup)
- Console shows:
  ```
  📩 Foreground message received: [MESSAGE_ID]
  📩 Title: Test Foreground
  📩 Body: This is a foreground test
  ✅ NotificationService: Local notification shown
  ```

**Troubleshooting**:
- If notification doesn't appear: Check notification permissions in device settings
- If only console logs appear: Verify flutter_local_notifications is initialized
- If no logs: Verify onMessage listener is set up

---

## Test 3: Background Notifications

**Objective**: Verify notifications work when app is minimized

**Steps**:
1. With app running, press home button to minimize (don't force close)
2. Send test notification from Firebase Console:
   - Title: "Test Background"
   - Body: "This is a background test"
   - Use your FCM token
3. Notification should appear in system tray
4. Tap the notification

**Expected Result**:
- Notification appears in system notification tray
- Tapping notification opens the app
- Console shows:
  ```
  📩 Notification opened app from background: [MESSAGE_ID]
  📩 Data: {...}
  ```

**Troubleshooting**:
- If notification doesn't appear: Check device notification settings
- If app doesn't open on tap: Verify onMessageOpenedApp listener
- Android: Verify FCM service in AndroidManifest.xml
- iOS: Verify background modes in Info.plist

---

## Test 4: Terminated State Notifications

**Objective**: Verify notifications work when app is completely closed

**Steps**:
1. Force close the app (swipe away from recent apps)
2. Wait 5 seconds
3. Send test notification from Firebase Console:
   - Title: "Test Terminated"
   - Body: "This is a terminated state test"
   - Use your FCM token
4. Tap the notification to open the app

**Expected Result**:
- Notification appears in system tray
- App launches when notification is tapped
- Console shows:
  ```
  📩 Notification opened app from terminated: [MESSAGE_ID]
  📩 Data: {...}
  ```

**Troubleshooting**:
- If no notification: Verify background refresh is enabled (iOS Settings)
- If notification appears but app doesn't launch: Check notification tap handling
- If app crashes: Check background message handler is top-level function

---

## Test 5: Notification Navigation

**Objective**: Verify notification data triggers correct navigation

**Steps**:
1. Send notification with custom data from Lambda or Postman:
   ```json
   {
     "userId": "YOUR_USER_ID",
     "title": "Navigation Test",
     "body": "Tap to navigate",
     "data": {
       "type": "food_reminder",
       "screen": "/home"
     }
   }
   ```
2. Tap the notification

**Expected Result**:
- App opens and navigates to specified screen
- Console shows:
  ```
  🔄 NotificationService: Handling navigation...
  📝 NotificationService: Data: {type: food_reminder, screen: /home}
  ✅ NotificationService: Navigation handled
  ```

**Test Cases**:
- `{"screen": "/home"}` → Home screen
- `{"screen": "/profile"}` → Profile screen
- `{"type": "food_reminder"}` → Home screen
- `{"type": "profile_update"}` → Profile screen

**Troubleshooting**:
- If navigation doesn't work: Check NavigationService is properly initialized
- If wrong screen: Verify data payload structure
- If app crashes: Check route exists in app_routes.dart

---

## Test 6: Token Refresh

**Objective**: Verify token refresh is handled correctly

**Steps**:
1. Sign in to the app (token is generated)
2. Uninstall and reinstall the app (forces token refresh)
3. Sign in again
4. Check console for:
   ```
   🔄 NotificationService: Token refreshed
   📝 NotificationService: New token: [NEW_TOKEN]
   ```

**Expected Result**:
- New token is generated
- New token is sent to backend
- Old token is replaced in local storage

**Troubleshooting**:
- If same token: This is normal if device hasn't changed
- If token not sent: Check onTokenRefresh listener

---

## Test 7: Notification Permissions

**Objective**: Verify permission handling works correctly

**Steps**:
1. Fresh install the app (or clear app data)
2. Sign in
3. When permission dialog appears:
   - First test: Grant permission
   - Second test: Deny permission
4. Check console logs

**Expected Result**:

**When Granted**:
```
✅ NotificationService: User granted permission
✅ NotificationService: FCM token received
```

**When Denied**:
```
⚠️ NotificationService: User declined permission
⚠️ NotificationService: FCM token is null
```

**Troubleshooting**:
- If dialog doesn't appear: Check permissions were reset
- iOS: Delete app and reinstall
- Android: Clear app data in settings

---

## Test 8: Sign Out Token Cleanup

**Objective**: Verify FCM token is deleted on sign out

**Steps**:
1. Sign in (token is generated)
2. Note the token from console
3. Sign out
4. Check console for:
   ```
   🔔 AuthViewModel: Deleting FCM token...
   ✅ NotificationService: Token deleted successfully
   ✅ AuthViewModel: FCM token deleted
   ```
5. Check that notification attempts to old token fail

**Expected Result**:
- Token is deleted from device
- Token is removed from local storage
- Backend no longer sends notifications to this device

---

## Test 9: Notification Preferences

**Objective**: Verify notification settings can be updated

**Steps**:
1. Sign in
2. From settings screen, toggle notifications on/off
3. Check console for:
   ```
   🔄 NotificationService: Updating preferences...
   ✅ NotificationService: Preferences updated successfully
   ```

**Expected Result**:
- Preferences are saved to backend
- User receives/doesn't receive notifications based on preference

---

## Test 10: Background Message Handler

**Objective**: Verify background handler processes messages correctly

**Steps**:
1. Force close the app
2. Send notification with data payload
3. Don't tap the notification
4. Open the app manually
5. Check console for background handler logs:
   ```
   📩 Background message received: [MESSAGE_ID]
   📩 Title: [TITLE]
   📩 Body: [BODY]
   📩 Data: {...}
   ```

**Expected Result**:
- Background handler processes message
- Data is logged (even if notification wasn't tapped)

---

## Automated Testing Script

Here's a curl command to test from backend:

```bash
# Set your variables
USER_ID="your_user_id_here"
FCM_TOKEN="your_fcm_token_here"
LAMBDA_URL="https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod"

# Send test notification
curl -X POST "$LAMBDA_URL/notifications/send" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -d '{
    "userId": "'"$USER_ID"'",
    "title": "Automated Test",
    "body": "This is an automated notification test",
    "data": {
      "type": "food_reminder",
      "screen": "/home",
      "timestamp": "'$(date +%s)'"
    }
  }'
```

---

## Common Issues & Solutions

### Issue: "No FCM token received"
**Solutions**:
- Verify Firebase is initialized before NotificationService
- Check google-services.json / GoogleService-Info.plist
- Ensure device has internet connection
- Check Firebase Console for project configuration

### Issue: "Notifications not displaying"
**Solutions**:
- Check notification permissions in device settings
- iOS: Settings → [App Name] → Notifications
- Android: Settings → Apps → [App Name] → Notifications
- Verify notification channel is created (Android)

### Issue: "Background handler not called"
**Solutions**:
- Ensure handler is top-level function with @pragma annotation
- Verify handler is registered before runApp()
- iOS: Check background refresh is enabled in Settings
- Android: Check battery optimization isn't blocking app

### Issue: "App crashes on notification tap"
**Solutions**:
- Check NavigationService is initialized
- Verify routes exist in app_routes.dart
- Check notification data structure is correct
- Review console logs for error messages

### Issue: "Token not sent to backend"
**Solutions**:
- Verify AWS Lambda endpoint is correct
- Check Firebase Auth token is valid
- Review network requests in logs
- Test backend endpoint with Postman

---

## Performance Testing

### Token Retrieval Time
- Should complete within 1-3 seconds
- Monitor with: `flutter run --profile`

### Notification Display Latency
- Foreground: < 1 second
- Background: < 2 seconds
- Terminated: < 3 seconds

### Battery Impact
- Monitor with: `adb shell dumpsys batterystats` (Android)
- iOS: Settings → Battery → Battery Usage

---

## Platform-Specific Notes

### iOS
- Notifications don't work in iOS Simulator (requires physical device)
- Background modes must be enabled in Xcode capabilities
- App must be code-signed for push notifications
- Silent notifications require `content-available: 1` in payload

### Android
- Notifications work in Android Emulator (with Google Play)
- Notification channels required for Android 8.0+
- Battery optimization may affect background notifications
- Custom notification icon should be white/transparent PNG

---

## Test Coverage Checklist

- [ ] FCM token retrieval on sign in
- [ ] Token stored locally
- [ ] Token sent to AWS backend
- [ ] Foreground notification display
- [ ] Background notification display
- [ ] Terminated state notification display
- [ ] Notification tap navigation (foreground)
- [ ] Notification tap navigation (background)
- [ ] Notification tap navigation (terminated)
- [ ] Token refresh handling
- [ ] Permission request (grant)
- [ ] Permission request (deny)
- [ ] Token deletion on sign out
- [ ] Token deletion on account deletion
- [ ] Notification preferences update
- [ ] Background message handler
- [ ] Multiple notification types
- [ ] Notification data parsing
- [ ] Error handling (no internet)
- [ ] Error handling (invalid token)

---

## Next Steps

After completing all tests:

1. Document any issues found
2. Create GitHub issues for bugs
3. Update implementation if needed
4. Test on multiple devices/OS versions
5. Perform load testing (multiple notifications)
6. Test with production Firebase credentials
7. Add analytics to track notification delivery rates

## Resources

- [Firebase Console](https://console.firebase.google.com/)
- [FCM REST API](https://firebase.google.com/docs/cloud-messaging/send-message)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/messaging/overview)
- [iOS Notification Guide](https://developer.apple.com/documentation/usernotifications)
- [Android Notification Guide](https://developer.android.com/develop/ui/views/notifications)
