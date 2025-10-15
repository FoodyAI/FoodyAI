# Send Notification Lambda Function

AWS Lambda function for sending push notifications to filtered user segments using Firebase Cloud Messaging (FCM).

## Overview

This Lambda function provides a flexible API for sending push notifications to users based on various filter criteria:

- **All users**: Send to all users with notifications enabled
- **Premium users**: Send to premium users only
- **Age-based**: Filter by age range (min/max)
- **Specific users**: Target specific user IDs
- **Custom filter**: Use custom SQL WHERE clause

## Features

- ✅ Multiple filter types for targeted notifications
- ✅ Batch sending for multiple users (handles 500+ tokens automatically)
- ✅ Automatic logging to `notifications_log` table
- ✅ Invalid token detection and cleanup
- ✅ Campaign support (tracks notifications by campaign ID)
- ✅ Rich notification options (images, badges, custom data)
- ✅ Comprehensive error handling and logging

## API Endpoint

**Method:** POST
**Path:** `/send-notification`

### Request Body

```json
{
  "filter": {
    "type": "all|premium|age|userIds|custom",
    // Additional filter parameters based on type
  },
  "notification": {
    "title": "Notification Title",
    "body": "Notification body text"
  },
  "data": {
    "screen": "/home",
    "type": "general",
    // Any custom key-value pairs
  },
  "options": {
    "imageUrl": "https://example.com/image.jpg",
    "badge": 1
  },
  "campaignId": "optional-campaign-uuid"
}
```

### Filter Types

#### 1. All Users

Send to all users with notifications enabled:

```json
{
  "filter": {
    "type": "all"
  }
}
```

#### 2. Premium Users

Send to premium users only:

```json
{
  "filter": {
    "type": "premium"
  }
}
```

#### 3. Age-Based Filter

Filter by age range:

```json
{
  "filter": {
    "type": "age",
    "minAge": 18,
    "maxAge": 30
  }
}
```

You can also use just `minAge` or just `maxAge`:

```json
{
  "filter": {
    "type": "age",
    "minAge": 25  // Users 25 and older
  }
}
```

#### 4. Specific User IDs

Target specific users:

```json
{
  "filter": {
    "type": "userIds",
    "userIds": ["user123", "user456", "user789"]
  }
}
```

#### 5. Custom SQL Filter

Use a custom SQL WHERE clause:

```json
{
  "filter": {
    "type": "custom",
    "whereClause": "age > 21 AND is_premium = true"
  }
}
```

⚠️ **Warning:** Be careful with custom filters to avoid SQL injection. Validate input carefully.

### Response

**Success (200):**

```json
{
  "success": true,
  "sentCount": 42,
  "failedCount": 3,
  "totalRecipients": 45,
  "invalidTokensCleared": 2,
  "message": "Sent to 42 users, 3 failed"
}
```

**No Recipients (200):**

```json
{
  "success": true,
  "message": "No target users found matching the filter criteria",
  "sentCount": 0,
  "failedCount": 0
}
```

**Error (400/500):**

```json
{
  "success": false,
  "error": "Error message",
  "message": "Detailed error information"
}
```

## Notification Options

### Basic Notification

```json
{
  "notification": {
    "title": "Hello!",
    "body": "Welcome to Foody"
  }
}
```

### With Custom Data

```json
{
  "notification": {
    "title": "New Recipe",
    "body": "Check out this recipe"
  },
  "data": {
    "screen": "/recipe/123",
    "recipeId": "123",
    "type": "recipe_notification"
  }
}
```

### With Image

```json
{
  "notification": {
    "title": "Beautiful Food",
    "body": "Look at this!"
  },
  "options": {
    "imageUrl": "https://example.com/food-image.jpg",
    "badge": 5
  }
}
```

## Database Logging

All sent notifications are logged to the `notifications_log` table:

```sql
CREATE TABLE notifications_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(255),
  notification_type VARCHAR(100) NOT NULL,  -- 'manual' or 'campaign'
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50) DEFAULT 'sent',        -- 'sent' or 'failed'
  error_message TEXT
);
```

## Invalid Token Handling

The function automatically:

1. Detects invalid/expired FCM tokens
2. Tracks them during sending
3. Clears them from the database (`fcm_token` set to NULL)
4. Reports count in response

## Rate Limiting

The function handles large batches automatically:

- Single device: Direct send
- 1-500 devices: Batch send
- 500+ devices: Split into multiple batches with 100ms delay between batches

## Testing

### Local Testing

```bash
cd aws-lambda/send-notification
npm install
node test-local.js
```

### AWS Testing

Use the provided test events in `test-events.json`:

```bash
aws lambda invoke \
  --function-name foody-send-notification \
  --payload file://test-events.json#testEvent_SendToAll \
  --region us-east-1 \
  response.json
```

## Deployment

### Prerequisites

1. AWS CLI configured
2. Lambda execution role with:
   - RDS access
   - CloudWatch Logs access
3. Environment variables set in `.env`:
   - `DB_HOST`
   - `DB_PORT`
   - `DB_NAME`
   - `DB_USER`
   - `DB_PASSWORD`
   - Firebase credentials

### Deploy

```bash
chmod +x deploy-send-notification.sh
./deploy-send-notification.sh
```

### Manual Deployment

1. Install dependencies:
   ```bash
   cd aws-lambda
   npm install
   ```

2. Create deployment package:
   ```bash
   cd send-notification
   zip -r ../send-notification.zip . ../firebase-admin.js ../notification-helpers.js ../node_modules
   ```

3. Upload to AWS Lambda:
   ```bash
   aws lambda update-function-code \
     --function-name foody-send-notification \
     --zip-file fileb://send-notification.zip \
     --region us-east-1
   ```

## API Gateway Integration

Create a POST endpoint:

1. **Resource:** `/send-notification`
2. **Method:** POST
3. **Integration:** Lambda Function (`foody-send-notification`)
4. **CORS:** Enabled
5. **Authorization:** API Key or Cognito (recommended)

Example API Gateway configuration:

```yaml
/send-notification:
  post:
    x-amazon-apigateway-integration:
      uri: arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:ACCOUNT_ID:function:foody-send-notification/invocations
      httpMethod: POST
      type: aws_proxy
```

## Security Considerations

1. **Authentication:** Protect the endpoint with API keys or IAM authentication
2. **Rate Limiting:** Implement API Gateway rate limiting
3. **Custom Filters:** Validate and sanitize custom SQL WHERE clauses
4. **Monitoring:** Set up CloudWatch alarms for high failure rates

## Monitoring

### CloudWatch Logs

The function logs detailed information:

- 📩 Notification request received
- 🔍 Filter criteria and target users
- 📤 Sending progress
- ✅ Success/failure counts
- 🗑️ Invalid tokens cleared

### CloudWatch Metrics

Monitor:

- Invocations
- Duration
- Errors
- Throttles

### Database Queries

Query notification statistics:

```sql
-- Success rate by notification type
SELECT
  notification_type,
  COUNT(*) as total,
  COUNT(CASE WHEN status = 'sent' THEN 1 END) as successful,
  COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed,
  ROUND(COUNT(CASE WHEN status = 'sent' THEN 1 END)::numeric / COUNT(*)::numeric * 100, 2) as success_rate
FROM notifications_log
GROUP BY notification_type;

-- Recent notifications
SELECT user_id, title, body, status, sent_at, error_message
FROM notifications_log
ORDER BY sent_at DESC
LIMIT 10;
```

## Error Handling

The function handles various error scenarios:

| Error | Status Code | Response |
|-------|-------------|----------|
| Missing required fields | 400 | Validation error message |
| Invalid filter type | 400 | "Invalid filter type: {type}" |
| No recipients found | 200 | Success with 0 sent count |
| Database error | 500 | Internal server error |
| Firebase error | 500 | Internal server error |

## Performance

- **Single device:** < 500ms
- **Batch (< 500):** 1-3 seconds
- **Large batch (1000+):** 5-10 seconds

## Example Use Cases

### 1. Welcome Notification (All Users)

```json
{
  "filter": { "type": "all" },
  "notification": {
    "title": "Welcome to Foody! 👋",
    "body": "Start your healthy eating journey today"
  },
  "data": { "screen": "/onboarding", "type": "welcome" }
}
```

### 2. Premium Feature Announcement

```json
{
  "filter": { "type": "premium" },
  "notification": {
    "title": "New Premium Feature! 🎉",
    "body": "Advanced meal planning is now available"
  },
  "data": { "screen": "/premium/meal-planner", "type": "feature" }
}
```

### 3. Age-Targeted Promotion

```json
{
  "filter": { "type": "age", "minAge": 18, "maxAge": 25 },
  "notification": {
    "title": "Student Discount! 🎓",
    "body": "Get 50% off premium with student ID"
  },
  "data": { "screen": "/offers/student", "type": "promotion" }
}
```

### 4. Personal Reminder

```json
{
  "filter": { "type": "userIds", "userIds": ["user123"] },
  "notification": {
    "title": "Don't Forget! ⏰",
    "body": "Log your dinner to complete today's tracking"
  },
  "data": { "screen": "/log-food", "type": "reminder" }
}
```

## Troubleshooting

### No notifications received

1. Check user has `notifications_enabled = true`
2. Verify user has valid `fcm_token`
3. Check CloudWatch logs for errors
4. Verify Firebase credentials are correct

### High failure rate

1. Check for invalid tokens (cleared automatically)
2. Verify Firebase project configuration
3. Check network connectivity to Firebase
4. Review CloudWatch logs for specific errors

### Slow performance

1. Check database query performance
2. Monitor batch sizes
3. Consider using campaigns for large sends
4. Review CloudWatch duration metrics

## Related Functions

- **notification-campaigns:** Create and schedule campaigns
- **user-profile:** Manage FCM tokens and preferences

## Support

For issues or questions:
1. Check CloudWatch logs
2. Review database logs
3. Consult Firebase documentation
4. Contact development team
