# Send Notification Lambda - Quick Reference Guide

## Overview

The `send-notification` Lambda function allows you to send push notifications to filtered user segments. This guide provides quick examples and common use cases.

## 📁 Files Created

```
aws-lambda/
├── send-notification/
│   ├── index.js              # Main Lambda function
│   ├── package.json          # Dependencies
│   ├── test-local.js         # Local testing script
│   ├── test-events.json      # AWS test events
│   └── README.md             # Full documentation
├── deploy-send-notification.sh  # Deployment script
└── SEND_NOTIFICATION_GUIDE.md   # This file
```

## 🚀 Quick Start

### 1. Deploy the Function

```bash
cd aws-lambda
./deploy-send-notification.sh
```

### 2. Test Locally

```bash
cd send-notification
npm install
node test-local.js
```

### 3. Test on AWS

```bash
aws lambda invoke \
  --function-name foody-send-notification \
  --payload '{"httpMethod":"POST","body":"{\"filter\":{\"type\":\"all\"},\"notification\":{\"title\":\"Test\",\"body\":\"Hello!\"}}"}' \
  --region us-east-1 \
  response.json

cat response.json
```

## 📊 Filter Types Cheat Sheet

| Filter Type | Use Case | Example |
|------------|----------|---------|
| `all` | Send to everyone | Welcome messages, major announcements |
| `premium` | Premium users only | Premium feature alerts, exclusive content |
| `age` | Age-based targeting | Age-appropriate content, student discounts |
| `userIds` | Specific users | Personal reminders, targeted messages |
| `custom` | Advanced filtering | Complex queries, multiple conditions |

## 💡 Common Examples

### Example 1: Welcome All Users

```bash
curl -X POST https://YOUR_API_GATEWAY/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "type": "all"
    },
    "notification": {
      "title": "Welcome to Foody! 👋",
      "body": "Start tracking your nutrition today"
    },
    "data": {
      "screen": "/home",
      "type": "welcome"
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "sentCount": 150,
  "failedCount": 5,
  "totalRecipients": 155,
  "invalidTokensCleared": 3,
  "message": "Sent to 150 users, 5 failed"
}
```

### Example 2: Premium Feature Alert

```bash
curl -X POST https://YOUR_API_GATEWAY/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "type": "premium"
    },
    "notification": {
      "title": "New Premium Feature! 🎉",
      "body": "Advanced meal planning is now available"
    },
    "data": {
      "screen": "/premium/meal-planner",
      "type": "feature_announcement"
    }
  }'
```

### Example 3: Age-Based Promotion

```bash
curl -X POST https://YOUR_API_GATEWAY/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "type": "age",
      "minAge": 18,
      "maxAge": 25
    },
    "notification": {
      "title": "Student Discount! 🎓",
      "body": "Get 50% off premium membership"
    },
    "data": {
      "screen": "/offers/student",
      "type": "promotion"
    }
  }'
```

### Example 4: Personal Reminder

```bash
curl -X POST https://YOUR_API_GATEWAY/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "type": "userIds",
      "userIds": ["abc123"]
    },
    "notification": {
      "title": "Log Your Dinner! ⏰",
      "body": "Don'\''t forget to complete today'\''s tracking"
    },
    "data": {
      "screen": "/log-food",
      "type": "reminder"
    }
  }'
```

### Example 5: With Image

```bash
curl -X POST https://YOUR_API_GATEWAY/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "type": "all"
    },
    "notification": {
      "title": "Healthy Recipe! 🥗",
      "body": "Try this delicious salad recipe"
    },
    "data": {
      "screen": "/recipe/123",
      "recipeId": "123",
      "type": "recipe"
    },
    "options": {
      "imageUrl": "https://your-s3-bucket.s3.amazonaws.com/recipe-123.jpg",
      "badge": 1
    }
  }'
```

### Example 6: Custom SQL Filter

```bash
curl -X POST https://YOUR_API_GATEWAY/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "type": "custom",
      "whereClause": "age > 21 AND is_premium = true AND goal = '\''lose_weight'\''"
    },
    "notification": {
      "title": "Weight Loss Tips 💪",
      "body": "Exclusive tips for premium members"
    },
    "data": {
      "screen": "/tips/weight-loss",
      "type": "tip"
    }
  }'
```

## 📱 Navigation Data

The `data` field is sent to the Flutter app and can be used for navigation:

```json
{
  "data": {
    "screen": "/home",           // Route to navigate to
    "type": "general",           // Notification type
    "recipeId": "123",           // Additional parameters
    "action": "open_detail"      // Custom action
  }
}
```

In Flutter ([notification_service.dart](../lib/services/notification_service.dart:311-338)), this data is handled:

```dart
void _handleNotificationNavigation(Map<String, dynamic> data) {
  final screen = data['screen'];
  final type = data['type'];

  if (screen != null) {
    NavigationService.pushNamed(screen);
  } else if (type == 'food_reminder') {
    NavigationService.pushNamed('/home');
  }
  // ... more navigation logic
}
```

## 🔍 Monitoring & Debugging

### Check CloudWatch Logs

```bash
aws logs tail /aws/lambda/foody-send-notification --follow --region us-east-1
```

### Query Database Logs

```sql
-- Recent notifications
SELECT
  user_id,
  title,
  body,
  status,
  sent_at,
  error_message
FROM notifications_log
ORDER BY sent_at DESC
LIMIT 20;

-- Success rate today
SELECT
  COUNT(*) as total,
  COUNT(CASE WHEN status = 'sent' THEN 1 END) as successful,
  COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed,
  ROUND(COUNT(CASE WHEN status = 'sent' THEN 1 END)::numeric / COUNT(*)::numeric * 100, 2) as success_rate
FROM notifications_log
WHERE sent_at >= CURRENT_DATE;

-- Notifications by type
SELECT
  notification_type,
  COUNT(*) as count
FROM notifications_log
WHERE sent_at >= CURRENT_DATE
GROUP BY notification_type;
```

## ⚠️ Common Issues

### Issue: No notifications received

**Solutions:**
1. Check user's `notifications_enabled` is `true`
2. Verify user has valid `fcm_token` in database
3. Check CloudWatch logs for errors
4. Test with a single user first using `userIds` filter

### Issue: High failure rate

**Solutions:**
1. Invalid tokens are automatically cleared
2. Check Firebase project configuration
3. Verify environment variables are set correctly
4. Review error messages in CloudWatch logs

### Issue: Slow performance

**Solutions:**
1. Use age-based or premium filters to reduce recipients
2. For very large sends (10,000+), use campaigns instead
3. Monitor CloudWatch duration metrics
4. Check database query performance

## 🔐 Security Best Practices

1. **Protect the endpoint** with API Gateway authentication
2. **Rate limit** API calls to prevent abuse
3. **Validate** custom SQL filters carefully
4. **Monitor** for unusual patterns in CloudWatch
5. **Audit** who can invoke the Lambda function

## 📊 Response Codes

| Status Code | Meaning | Action |
|-------------|---------|--------|
| 200 | Success | Notifications sent successfully |
| 400 | Bad Request | Check request format and required fields |
| 405 | Method Not Allowed | Use POST method |
| 500 | Server Error | Check CloudWatch logs |

## 🧪 Testing Checklist

Before deploying to production:

- [ ] Test with single user (`userIds` filter)
- [ ] Test with small group (< 10 users)
- [ ] Test all filter types
- [ ] Verify database logging works
- [ ] Check invalid token cleanup
- [ ] Test notification navigation in app
- [ ] Monitor CloudWatch metrics
- [ ] Test error scenarios (missing fields, invalid filter)

## 📈 Scaling Considerations

| Recipients | Expected Duration | Strategy |
|-----------|------------------|----------|
| 1-10 | < 1 second | Direct send |
| 10-100 | 1-3 seconds | Batch send |
| 100-500 | 3-5 seconds | Single batch |
| 500-5,000 | 5-20 seconds | Multiple batches |
| 5,000+ | Use campaigns | Schedule and track |

For large-scale sends, consider using the **notification-campaigns** Lambda (Issue #5).

## 🔄 Integration with Other Services

### With User Profile Service

Users are automatically added to the notification system when they:
1. Log in (FCM token sent via [aws_service.dart](../lib/services/aws_service.dart:498-548))
2. Update preferences ([notification_service.dart](../lib/services/notification_service.dart:341-365))

### With Campaign Manager (Future)

```json
{
  "filter": { "type": "premium" },
  "notification": { "title": "...", "body": "..." },
  "campaignId": "campaign-uuid-from-campaign-manager"
}
```

Campaign statistics are automatically updated when `campaignId` is provided.

## 📞 Support

For issues:
1. Check [README.md](send-notification/README.md) for detailed documentation
2. Review CloudWatch logs: `/aws/lambda/foody-send-notification`
3. Query `notifications_log` table for delivery status
4. Contact development team with error details

## 🎯 Next Steps

After implementing send-notification:

1. **Issue #5**: Implement notification campaigns for scheduled sends
2. **Issue #6**: Add notification preferences UI in Flutter
3. **Issue #8**: Comprehensive testing of all notification flows

---

**Quick Links:**
- [Full Documentation](send-notification/README.md)
- [Lambda Function Code](send-notification/index.js)
- [Test Events](send-notification/test-events.json)
- [Deployment Script](deploy-send-notification.sh)
