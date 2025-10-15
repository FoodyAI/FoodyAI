# Notification Campaigns Lambda Function

AWS Lambda function for creating, managing, and sending notification campaigns with scheduling capabilities.

## Overview

This Lambda function provides a complete campaign management system with:

- ✅ Campaign CRUD operations (Create, Read, Update, Delete)
- ✅ Campaign scheduling for future sending
- ✅ Integration with send-notification Lambda function
- ✅ Campaign statistics tracking (sent, delivered, failed)
- ✅ Campaign status management (draft, scheduled, sending, sent, failed)
- ✅ API Gateway endpoints for all operations

## Features

### Campaign Management
- Create draft campaigns
- Schedule campaigns for future sending
- Update campaign details
- Delete campaigns
- Track campaign statistics

### Campaign Status Flow
```
draft → scheduled → sending → sent
  ↓         ↓         ↓
failed ← failed ← failed
```

### Integration
- Integrates with `send-notification` Lambda function
- Uses existing database schema (`notification_campaigns` table)
- Supports all filter types from send-notification function

## API Endpoints

### Create Campaign
**POST** `/campaigns`

```json
{
  "campaignName": "Welcome Campaign",
  "title": "Welcome to Foody!",
  "body": "Start tracking your nutrition today",
  "data": {
    "screen": "/home",
    "type": "welcome"
  },
  "filterCriteria": {
    "type": "all"
  },
  "scheduledAt": "2025-10-16T10:00:00Z",
  "createdBy": "admin"
}
```

### List Campaigns
**GET** `/campaigns?status=draft&limit=10&offset=0`

Query Parameters:
- `status` (optional): Filter by status (draft, scheduled, sending, sent, failed)
- `limit` (optional): Number of campaigns to return (default: 50)
- `offset` (optional): Number of campaigns to skip (default: 0)

### Get Campaign
**GET** `/campaigns/{id}`

### Update Campaign
**PUT** `/campaigns/{id}`

```json
{
  "title": "Updated Title",
  "body": "Updated body content",
  "status": "scheduled",
  "scheduledAt": "2025-10-16T12:00:00Z"
}
```

### Send Campaign
**POST** `/campaigns/{id}/send`

Sends the campaign immediately, regardless of scheduled time.

### Delete Campaign
**DELETE** `/campaigns/{id}`

## Response Format

### Success Response
```json
{
  "success": true,
  "campaign": {
    "id": "uuid",
    "campaignName": "Welcome Campaign",
    "title": "Welcome to Foody!",
    "body": "Start tracking your nutrition today",
    "data": {...},
    "filterCriteria": {...},
    "status": "draft",
    "scheduledAt": null,
    "sentAt": null,
    "createdAt": "2025-10-15T22:00:00Z",
    "updatedAt": "2025-10-15T22:00:00Z",
    "createdBy": "admin",
    "totalRecipients": 0,
    "successfulSends": 0,
    "failedSends": 0,
    "notes": null
  },
  "message": "Campaign created successfully"
}
```

### List Response
```json
{
  "success": true,
  "campaigns": [...],
  "pagination": {
    "total": 25,
    "limit": 10,
    "offset": 0,
    "hasMore": true
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": "Campaign not found"
}
```

## Campaign Statuses

- **draft**: Campaign created but not scheduled
- **scheduled**: Campaign scheduled for future sending
- **sending**: Campaign is currently being sent
- **sent**: Campaign has been sent successfully
- **failed**: Campaign failed to send

## Filter Criteria

Supports all filter types from the send-notification function:

```json
{
  "type": "all",           // All users with notifications enabled
  "type": "premium",       // Premium users only
  "type": "age",           // Users with age < X or age > X
  "type": "custom",        // Custom SQL WHERE clause
  "userIds": ["id1", "id2"] // Specific user IDs
}
```

## Local Testing

```bash
cd notification-campaigns
npm install
node test-local.js
```

## Deployment

```bash
# Install dependencies
npm install

# Deploy to AWS Lambda
npm run deploy
```

## Environment Variables

Required environment variables:
- `DB_HOST`: Database host
- `DB_PORT`: Database port
- `DB_NAME`: Database name
- `DB_USER`: Database username
- `DB_PASSWORD`: Database password

## Dependencies

- `pg`: PostgreSQL client
- `uuid`: UUID generation

## Error Handling

The function includes comprehensive error handling:
- Database connection errors
- Validation errors
- Campaign not found errors
- Send notification integration errors

## Monitoring

Monitor the function using:
- CloudWatch Logs
- CloudWatch Metrics
- Database query logs
- Campaign statistics in database
