# FCM Token Lambda Function Fix - Deployment Guide

## Problem Summary

The `fcm_token` field was not being saved to the database even though the Lambda function returned a 200 status code. This was because the Lambda function's update logic did not include the `fcmToken` and `notificationsEnabled` fields in the UPDATE query.

## Root Cause

The `user-profile` Lambda function (index.js) had:
- ✅ Database columns exist: `fcm_token` and `notifications_enabled`
- ❌ Lambda INSERT query: Missing these fields
- ❌ Lambda UPDATE query: Missing these fields in dynamic update logic

## Changes Made

### File: `aws-lambda/user-profile/index.js`

#### 1. INSERT Query (New Users) - Lines 78-108
**Added:**
- `fcm_token` column to INSERT statement
- `notifications_enabled` column to INSERT statement
- Default value for `notifications_enabled` = `true`

**Before:**
```javascript
INSERT INTO users (
  user_id, email, display_name, photo_url, gender, age, weight, height,
  activity_level, goal, daily_calories, bmi, theme_preference, ai_provider,
  measurement_unit, created_at, updated_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
```

**After:**
```javascript
INSERT INTO users (
  user_id, email, display_name, photo_url, gender, age, weight, height,
  activity_level, goal, daily_calories, bmi, theme_preference, ai_provider,
  measurement_unit, fcm_token, notifications_enabled, created_at, updated_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
```

#### 2. UPDATE Query (Existing Users) - Lines 183-190
**Added:**
```javascript
if (userData.fcmToken !== undefined) {
  updateFields.push(`fcm_token = $${paramIndex++}`);
  updateValues.push(userData.fcmToken);
}
if (userData.notificationsEnabled !== undefined) {
  updateFields.push(`notifications_enabled = $${paramIndex++}`);
  updateValues.push(userData.notificationsEnabled);
}
```

## Deployment Instructions

### Method 1: AWS Console (Recommended for Quick Fix)

1. **Navigate to Lambda Console:**
   - Go to: https://console.aws.amazon.com/lambda
   - Find function: `user-profile` (or your function name)

2. **Upload Code:**
   - Click "Upload from" → ".zip file"
   - Select: `aws-lambda/user-profile-fcm-fix.zip`
   - Click "Save"

3. **Verify Deployment:**
   - Check that "Last modified" timestamp updated
   - Function code should show the new changes

### Method 2: AWS CLI

```bash
cd c:/flutter_project/Foody/aws-lambda

# Update the Lambda function
aws lambda update-function-code \
  --function-name user-profile \
  --zip-file fileb://user-profile-fcm-fix.zip \
  --region us-east-1

# Wait for update to complete
aws lambda wait function-updated \
  --function-name user-profile \
  --region us-east-1

echo "✅ Lambda function updated successfully"
```

### Method 3: Using Existing Deploy Script

```bash
cd c:/flutter_project/Foody/aws-lambda

# If you have a deploy script, update the function name
./deploy.sh user-profile
```

## Testing After Deployment

### 1. Clear Your FCM Token (Optional)
If you want to re-test from scratch:
```sql
UPDATE users
SET fcm_token = NULL, notifications_enabled = true
WHERE user_id = 'YOUR_USER_ID';
```

### 2. Re-run the Flutter App
```bash
cd c:/flutter_project/Foody
flutter run
```

### 3. Sign In and Check Logs
You should see:
```
✅ NotificationService: FCM token received
📝 NotificationService: Token: [YOUR_TOKEN]
🔄 NotificationService: Sending token to backend...
🔄 AWS Service: Updating FCM token...
📝 AWS Service: User ID: [USER_ID]
📥 AWS Service: FCM token update response status: 200
📥 AWS Service: FCM token update response data: {success: true, ...}
✅ AWS Service: FCM token updated successfully
✅ NotificationService: Token sent to backend successfully
```

### 4. Verify in Database

**Option A: AWS Console (RDS Query Editor)**
```sql
SELECT user_id, email, fcm_token, notifications_enabled, last_token_update
FROM users
WHERE user_id = 'YOUR_USER_ID';
```

**Expected Result:**
```
user_id              | email           | fcm_token                           | notifications_enabled | last_token_update
---------------------|-----------------|-------------------------------------|----------------------|-------------------
XKO61eTIQtW9PVX...  | user@email.com  | cBlDVSIpS3ua5P-Cbi4A5l:APA91b...   | true                 | 2025-01-14 23:15:00
```

**Option B: Using psql**
```bash
psql -h your-rds-endpoint.amazonaws.com \
     -U your-db-user \
     -d your-db-name \
     -c "SELECT user_id, email, LEFT(fcm_token, 20) as token_preview, notifications_enabled FROM users WHERE fcm_token IS NOT NULL;"
```

### 5. Test Notification Sending
Once token is saved, test sending a notification:

```bash
# Using Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Paste your FCM token
4. Click "Test"

# OR using your backend Lambda
curl -X POST https://your-api.amazonaws.com/prod/notifications/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -d '{
    "userId": "YOUR_USER_ID",
    "title": "Test Notification",
    "body": "Testing FCM after Lambda fix"
  }'
```

## Verification Checklist

After deployment, verify:

- [ ] Lambda function code updated (check Last Modified timestamp)
- [ ] Flutter app receives 200 status code (no more 400 errors)
- [ ] Database shows `fcm_token` value (not NULL)
- [ ] Database shows `notifications_enabled` = true
- [ ] Database shows `last_token_update` timestamp
- [ ] Test notification successfully delivered to device
- [ ] Token persists after app restart

## Rollback Instructions

If something goes wrong:

### Rollback to Previous Version
```bash
# List recent versions
aws lambda list-versions-by-function \
  --function-name user-profile \
  --region us-east-1

# Rollback to previous version (e.g., version 42)
aws lambda update-function-configuration \
  --function-name user-profile \
  --revision-id PREVIOUS_REVISION_ID \
  --region us-east-1
```

### Or Re-upload Previous ZIP
```bash
aws lambda update-function-code \
  --function-name user-profile \
  --zip-file fileb://user-profile-updated.zip \
  --region us-east-1
```

## Additional Notes

### Database Schema Verification
Ensure these columns exist in your `users` table:
```sql
-- Check if columns exist
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN ('fcm_token', 'notifications_enabled', 'last_token_update');
```

If columns don't exist, run:
```sql
-- From push-notification-schema.sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_token_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
```

### Monitoring

After deployment, monitor for errors:
```bash
# Watch CloudWatch logs
aws logs tail /aws/lambda/user-profile --follow --region us-east-1
```

### Performance Impact

The added fields have minimal impact:
- **fcm_token**: TEXT field, indexed, ~180 bytes per token
- **notifications_enabled**: BOOLEAN, 1 byte
- **Storage**: ~181 bytes per user
- **Index**: Creates index on `fcm_token` for fast lookups

## Common Issues

### Issue 1: "Column fcm_token does not exist"
**Solution:** Run the notification schema SQL:
```bash
cd aws-lambda
psql -h your-endpoint -U user -d dbname -f push-notification-schema.sql
```

### Issue 2: "Permission denied for table users"
**Solution:** Grant Lambda execution role UPDATE permission:
```sql
GRANT UPDATE ON users TO lambda_execution_role;
```

### Issue 3: Still getting NULL in database
**Solution:**
1. Check Lambda CloudWatch logs for errors
2. Verify payload includes `fcmToken` field (camelCase)
3. Ensure Flutter app is sending email + fcmToken together

## Files Modified

1. **aws-lambda/user-profile/index.js** - Lambda function handler
   - Lines 78-108: INSERT query updated
   - Lines 183-190: UPDATE logic updated

2. **aws-lambda/user-profile-fcm-fix.zip** - Deployment package
   - Contains: index.js, package.json, package-lock.json

## Success Criteria

✅ Lambda deployed successfully
✅ Flutter app sends FCM token without errors
✅ Database shows fcm_token value
✅ Test notification delivered to device
✅ CloudWatch logs show no errors

## Next Steps

After successful deployment:

1. Test on multiple devices (iOS & Android)
2. Test token refresh scenarios
3. Test notification preferences update
4. Implement notification analytics
5. Set up monitoring alerts for failed token updates

## Support

If you encounter issues:
1. Check CloudWatch logs: `/aws/lambda/user-profile`
2. Verify database columns exist
3. Test with Postman/curl directly
4. Check Flutter console logs for request payload
5. Review Lambda execution role permissions

## Changelog

**Version 1.1.0** - 2025-01-14
- Added `fcm_token` field to INSERT query
- Added `notifications_enabled` field to INSERT query
- Added `fcmToken` handling to UPDATE query
- Added `notificationsEnabled` handling to UPDATE query
- Default `notifications_enabled` = true for new users

**Version 1.0.0** - Initial version
- Basic user profile CRUD operations
