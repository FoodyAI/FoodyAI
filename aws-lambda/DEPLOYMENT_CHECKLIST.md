# 🚀 Push Notification Deployment Checklist

Use this checklist to deploy the push notification system to production.

## ✅ Pre-Deployment Checklist

### 1. Environment Setup

- [ ] AWS CLI installed and configured
- [ ] AWS credentials have necessary permissions:
  - Lambda full access
  - RDS data access
  - CloudWatch logs access
  - API Gateway access
- [ ] Node.js 18.x installed locally
- [ ] Firebase project created
- [ ] Firebase service account key downloaded

### 2. Configuration Files

- [ ] `.env` file created in `aws-lambda/` directory
- [ ] Database credentials added to `.env`:
  ```bash
  DB_HOST=your-rds-endpoint.rds.amazonaws.com
  DB_PORT=5432
  DB_NAME=foody_db
  DB_USER=your_username
  DB_PASSWORD=your_password
  ```
- [ ] Firebase credentials added to `.env`:
  ```bash
  FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
  # OR
  FIREBASE_PROJECT_ID=your-project-id
  FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----..."
  FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@....iam.gserviceaccount.com
  ```
- [ ] `firebase-service-account.json` placed in `aws-lambda/` directory
- [ ] `.gitignore` updated to exclude sensitive files:
  ```
  .env
  firebase-service-account.json
  ```

### 3. Database Preparation

- [ ] RDS instance running and accessible
- [ ] Database connection tested:
  ```bash
  psql -h your-rds-endpoint -U your_username -d foody_db
  ```
- [ ] Existing `users` table has basic structure
- [ ] Database backup created before schema changes

---

## 📦 Deployment Steps

### Step 1: Deploy Database Schema

```bash
cd aws-lambda

# Review the schema first
cat push-notification-schema.sql

# Deploy the schema
./deploy-notification-schema.sh

# Or manually:
psql -h your-rds-endpoint -U your_username -d foody_db -f push-notification-schema.sql
```

**Verification:**
```sql
-- Check new columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN ('fcm_token', 'notifications_enabled', 'is_premium', 'last_token_update');

-- Check new tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_name IN ('notifications_log', 'notification_campaigns');

-- Check indexes exist
SELECT indexname
FROM pg_indexes
WHERE tablename IN ('users', 'notifications_log', 'notification_campaigns');
```

- [ ] All columns added successfully
- [ ] All tables created
- [ ] All indexes created
- [ ] Triggers working
- [ ] Views created

### Step 2: Install Dependencies

```bash
cd aws-lambda

# Install all dependencies
npm install

# Verify firebase-admin installed
npm list firebase-admin
```

- [ ] `node_modules/` directory created
- [ ] `firebase-admin` package installed
- [ ] `pg` package installed

### Step 3: Test Firebase Connection Locally

```bash
cd aws-lambda

# Create a test script
node -e "
const { initializeFirebase, getMessaging } = require('./firebase-admin');
try {
  initializeFirebase();
  console.log('✅ Firebase initialized successfully');
} catch (error) {
  console.error('❌ Firebase initialization failed:', error.message);
}
"
```

- [ ] Firebase initializes without errors
- [ ] No credential errors

### Step 4: Update User Profile Lambda

The user-profile Lambda is already updated. Just redeploy it:

```bash
cd aws-lambda/user-profile

# Create deployment package
zip -r ../user-profile-updated.zip .

# Update Lambda function
aws lambda update-function-code \
  --function-name foody-user-profile \
  --zip-file fileb://../user-profile-updated.zip \
  --region us-east-1
```

- [ ] User profile Lambda updated
- [ ] Test user profile update with FCM token

### Step 5: Deploy Send Notification Lambda

```bash
cd aws-lambda

# Make script executable
chmod +x deploy-send-notification.sh

# Edit the script and update ROLE_ARN
# ROLE_ARN="arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role"

# Deploy
./deploy-send-notification.sh
```

**If deployment script doesn't work, manual deployment:**

```bash
# Create temp directory
mkdir -p temp/send-notification
cp -r send-notification/* temp/send-notification/
cp firebase-admin.js temp/send-notification/
cp notification-helpers.js temp/send-notification/
cp -r node_modules temp/send-notification/

# Create ZIP
cd temp/send-notification
zip -r ../../send-notification.zip .
cd ../..

# Upload to Lambda
aws lambda create-function \
  --function-name foody-send-notification \
  --runtime nodejs18.x \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role \
  --handler index.handler \
  --zip-file fileb://send-notification.zip \
  --timeout 60 \
  --memory-size 512 \
  --region us-east-1

# Set environment variables
aws lambda update-function-configuration \
  --function-name foody-send-notification \
  --environment Variables={DB_HOST=...,DB_PORT=5432,...} \
  --region us-east-1

# Cleanup
rm -rf temp send-notification.zip
```

- [ ] Lambda function created
- [ ] Environment variables set
- [ ] Timeout set to 60 seconds
- [ ] Memory set to 512 MB

### Step 6: Configure API Gateway

**Option A: AWS Console**

1. Go to API Gateway console
2. Create or select existing API
3. Create resource: `/send-notification`
4. Create method: `POST`
5. Integration type: Lambda Function
6. Select `foody-send-notification`
7. Enable CORS
8. Deploy API to stage (e.g., `prod`)

**Option B: AWS CLI**

```bash
# Get API ID
API_ID=$(aws apigateway get-rest-apis --query 'items[?name==`foody-api`].id' --output text)

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`/`].id' --output text)

# Create resource
RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part send-notification \
  --query 'id' --output text)

# Create POST method
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE

# Set up Lambda integration
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:YOUR_ACCOUNT_ID:function:foody-send-notification/invocations

# Enable CORS
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE

# Deploy API
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod
```

- [ ] API Gateway resource created
- [ ] POST method configured
- [ ] Lambda integration set up
- [ ] CORS enabled
- [ ] API deployed

**Note your API endpoint:**
```
https://[API_ID].execute-api.us-east-1.amazonaws.com/prod/send-notification
```

### Step 7: Grant Lambda Permissions

```bash
# Allow API Gateway to invoke Lambda
aws lambda add-permission \
  --function-name foody-send-notification \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:YOUR_ACCOUNT_ID:YOUR_API_ID/*/POST/send-notification"
```

- [ ] Lambda permission added for API Gateway

---

## 🧪 Testing Steps

### Test 1: Test Lambda Directly

```bash
# Create test event
cat > test-event.json << 'EOF'
{
  "httpMethod": "POST",
  "body": "{\"filter\":{\"type\":\"userIds\",\"userIds\":[\"YOUR_USER_ID\"]},\"notification\":{\"title\":\"Test Notification\",\"body\":\"Testing from Lambda\"}}"
}
EOF

# Invoke Lambda
aws lambda invoke \
  --function-name foody-send-notification \
  --payload file://test-event.json \
  --region us-east-1 \
  response.json

# Check response
cat response.json
```

- [ ] Lambda invokes successfully
- [ ] Response shows success
- [ ] CloudWatch logs show execution

### Test 2: Test via API Gateway

```bash
# Test with curl
curl -X POST \
  https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "type": "userIds",
      "userIds": ["YOUR_USER_ID"]
    },
    "notification": {
      "title": "API Test",
      "body": "Testing from API Gateway"
    }
  }'
```

- [ ] API returns 200 status
- [ ] Response includes sentCount
- [ ] Notification received on device

### Test 3: Verify Database Logging

```sql
-- Check notification was logged
SELECT *
FROM notifications_log
ORDER BY sent_at DESC
LIMIT 5;

-- Check user's FCM token
SELECT user_id, fcm_token, notifications_enabled
FROM users
WHERE user_id = 'YOUR_USER_ID';
```

- [ ] Notification logged in database
- [ ] Status is 'sent'
- [ ] User has valid FCM token

### Test 4: Test All Filter Types

```bash
# Test premium filter
curl -X POST YOUR_API/send-notification -H "Content-Type: application/json" \
  -d '{"filter":{"type":"premium"},"notification":{"title":"Premium Test","body":"Test"}}'

# Test age filter
curl -X POST YOUR_API/send-notification -H "Content-Type: application/json" \
  -d '{"filter":{"type":"age","minAge":18,"maxAge":30},"notification":{"title":"Age Test","body":"Test"}}'

# Test all users
curl -X POST YOUR_API/send-notification -H "Content-Type: application/json" \
  -d '{"filter":{"type":"all"},"notification":{"title":"All Users Test","body":"Test"}}'
```

- [ ] Premium filter works
- [ ] Age filter works
- [ ] All users filter works

### Test 5: Test Flutter App Integration

1. Open Flutter app
2. Log in with test user
3. Check logs for FCM token sent to backend
4. Send test notification from Lambda
5. Verify notification received
6. Tap notification
7. Verify navigation works

- [ ] FCM token sent on login
- [ ] Notification received in foreground
- [ ] Notification received in background
- [ ] Notification tap navigation works
- [ ] Token refresh works

---

## 🔍 Monitoring Setup

### CloudWatch Logs

```bash
# View logs in real-time
aws logs tail /aws/lambda/foody-send-notification --follow --region us-east-1
```

- [ ] CloudWatch log group exists
- [ ] Logs are being written
- [ ] No critical errors

### CloudWatch Alarms

Create alarms for:

```bash
# High error rate alarm
aws cloudwatch put-metric-alarm \
  --alarm-name foody-send-notification-errors \
  --alarm-description "Alert when error rate is high" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=foody-send-notification
```

- [ ] Error rate alarm created
- [ ] Duration alarm created
- [ ] Throttle alarm created

---

## 🔐 Security Checklist

- [ ] API Gateway has authentication enabled (API Key or Cognito)
- [ ] Rate limiting configured on API Gateway
- [ ] Lambda execution role has minimum required permissions
- [ ] Database credentials encrypted
- [ ] Firebase service account key secured
- [ ] `.env` file not committed to git
- [ ] CloudWatch logs don't contain sensitive data
- [ ] CORS configured correctly (not `*` in production)

---

## 📊 Post-Deployment Verification

### Database Queries

```sql
-- Count users with FCM tokens
SELECT COUNT(*) as users_with_tokens
FROM users
WHERE fcm_token IS NOT NULL;

-- Count eligible notification recipients
SELECT COUNT(*) as eligible_users
FROM users
WHERE notifications_enabled = true
  AND fcm_token IS NOT NULL;

-- Recent notifications
SELECT
  notification_type,
  COUNT(*) as count,
  COUNT(CASE WHEN status = 'sent' THEN 1 END) as successful
FROM notifications_log
WHERE sent_at >= CURRENT_DATE
GROUP BY notification_type;
```

- [ ] Users have FCM tokens
- [ ] Notifications are being sent
- [ ] Success rate is high (> 90%)

### Performance Metrics

- [ ] Lambda execution time < 5 seconds for small batches
- [ ] Lambda execution time < 30 seconds for large batches
- [ ] Database queries use indexes (check EXPLAIN)
- [ ] No timeout errors

---

## 🎉 Deployment Complete!

Once all items are checked:

- [ ] All Lambda functions deployed
- [ ] Database schema updated
- [ ] API Gateway configured
- [ ] All tests passing
- [ ] Monitoring set up
- [ ] Security configured
- [ ] Documentation reviewed

---

## 📞 Troubleshooting

### Issue: Lambda timeout

**Solution:** Increase timeout in Lambda configuration
```bash
aws lambda update-function-configuration \
  --function-name foody-send-notification \
  --timeout 120
```

### Issue: Database connection error

**Solutions:**
- Check security group allows Lambda IP range
- Verify RDS is publicly accessible (or Lambda in VPC)
- Check database credentials in environment variables
- Test connection from EC2 instance in same VPC

### Issue: Firebase authentication error

**Solutions:**
- Verify service account key is correct
- Check Firebase project ID matches
- Ensure service account has "Firebase Admin SDK Administrator Service Agent" role
- Test Firebase initialization locally

### Issue: No notifications received

**Solutions:**
- Check user has `notifications_enabled = true`
- Verify FCM token is valid and not NULL
- Check CloudWatch logs for errors
- Test with Firebase Console (Messaging → Send test message)
- Verify Firebase project has Cloud Messaging enabled

### Issue: High failure rate

**Solutions:**
- Check for invalid tokens (automatically cleaned)
- Verify Firebase project configuration
- Review error messages in `notifications_log` table
- Check CloudWatch logs for pattern

---

## 📝 Rollback Plan

If something goes wrong:

1. **Rollback Lambda:**
   ```bash
   aws lambda update-function-code \
     --function-name foody-send-notification \
     --s3-bucket your-backup-bucket \
     --s3-key previous-version.zip
   ```

2. **Rollback Database Schema:**
   ```sql
   -- Remove new columns
   ALTER TABLE users DROP COLUMN IF EXISTS fcm_token;
   ALTER TABLE users DROP COLUMN IF EXISTS notifications_enabled;
   ALTER TABLE users DROP COLUMN IF EXISTS last_token_update;
   ALTER TABLE users DROP COLUMN IF EXISTS is_premium;

   -- Drop new tables
   DROP TABLE IF EXISTS notifications_log;
   DROP TABLE IF EXISTS notification_campaigns;
   ```

3. **Disable API Gateway:**
   ```bash
   aws apigateway delete-stage \
     --rest-api-id YOUR_API_ID \
     --stage-name prod
   ```

---

**Deployment Date:** _____________

**Deployed By:** _____________

**Version:** 1.0.0

**Status:** ⬜ Pending | ⬜ In Progress | ⬜ Complete | ⬜ Failed
