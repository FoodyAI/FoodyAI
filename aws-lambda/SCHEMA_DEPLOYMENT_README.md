# Push Notification Schema Deployment Guide

## Overview

This guide explains how to deploy the push notification database schema to your AWS RDS PostgreSQL database. This is **Issue #1** in the push notification implementation and is **critical** as it blocks all other work.

## Files Created

1. **push-notification-schema.sql** - Complete database schema with tables, indexes, triggers, and views
2. **deploy-notification-schema.sh** - Automated deployment script
3. **validate-notification-schema.sh** - Validation and testing script

## Prerequisites

Before deploying, ensure you have:

- PostgreSQL client (`psql`) installed on your machine
- Access to your AWS RDS PostgreSQL database
- Database credentials (host, port, database name, username, password)
- RDS Security Group configured to allow your IP address

### Install PostgreSQL Client

**macOS:**
```bash
brew install postgresql
```

**Ubuntu/Debian:**
```bash
sudo apt-get install postgresql-client
```

**Windows:**
Download from [PostgreSQL Downloads](https://www.postgresql.org/download/windows/)

## Deployment Steps

### Method 1: Automated Deployment (Recommended)

#### Step 1: Set Environment Variables (Optional)

Create a `.env` file in your project root with your database credentials:

```bash
# .env
DB_HOST=your-rds-endpoint.amazonaws.com
DB_PORT=5432
DB_NAME=foody
DB_USER=postgres
DB_PASSWORD=your-secure-password
```

**Note:** Add `.env` to your `.gitignore` to avoid committing credentials!

#### Step 2: Run Deployment Script

```bash
./deploy-notification-schema.sh
```

The script will:
1. Check prerequisites (psql installed, schema file exists)
2. Load credentials from .env or prompt you for them
3. Test database connection
4. Create a backup of your current schema
5. Deploy the new schema
6. Verify deployment success
7. Run sample validation queries
8. Show a summary report

#### Step 3: Validate Deployment

```bash
./validate-notification-schema.sh
```

This runs comprehensive validation queries to ensure everything is set up correctly.

### Method 2: Manual Deployment

If you prefer to deploy manually:

#### Step 1: Connect to RDS Database

```bash
psql -h your-rds-endpoint.amazonaws.com \
     -p 5432 \
     -U postgres \
     -d foody
```

#### Step 2: Execute Schema File

```sql
\i push-notification-schema.sql
```

Or from command line:

```bash
psql -h your-rds-endpoint.amazonaws.com \
     -p 5432 \
     -U postgres \
     -d foody \
     -f push-notification-schema.sql
```

#### Step 3: Verify Manually

Run these queries to verify:

```sql
-- Check users table columns
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN ('fcm_token', 'notifications_enabled', 'is_premium', 'last_token_update');

-- Check notifications_log table
\d notifications_log

-- Check notification_campaigns table
\d notification_campaigns

-- Check indexes
\di *notification*

-- Check triggers
\dS *token*

-- Check views
\dv v_*notification*
```

## What Gets Created

### 1. Users Table Modifications

Four new columns added to the existing `users` table:

| Column | Type | Default | Description |
|--------|------|---------|-------------|
| `fcm_token` | TEXT | NULL | Firebase Cloud Messaging device token |
| `notifications_enabled` | BOOLEAN | true | User's notification preference |
| `last_token_update` | TIMESTAMP | CURRENT_TIMESTAMP | When FCM token was last updated |
| `is_premium` | BOOLEAN | false | Premium user flag for filtering |

### 2. New Tables

#### notifications_log
Tracks all sent notifications for analytics and debugging.

**Key columns:**
- `id` (UUID) - Primary key
- `user_id` - Reference to users table
- `notification_type` - Type (manual, campaign, automated)
- `title`, `body` - Notification content
- `data` (JSONB) - Additional payload data
- `sent_at` - Timestamp
- `status` - Delivery status (sent, failed, etc.)
- `error_message` - Error details if failed

#### notification_campaigns
Manages bulk notification campaigns with scheduling.

**Key columns:**
- `id` (UUID) - Primary key
- `campaign_name` - Friendly name
- `title`, `body` - Notification content
- `data` (JSONB) - Additional payload
- `filter_criteria` (JSONB) - User filtering rules
- `scheduled_at` - When to send (NULL = immediate)
- `status` - Campaign status (draft, scheduled, sent, etc.)
- `total_recipients`, `successful_sends`, `failed_sends` - Statistics

### 3. Indexes (10 total)

Performance indexes for fast queries:
- `idx_users_fcm_token` - Find users by FCM token
- `idx_users_notifications_enabled` - Filter notification-enabled users
- `idx_users_is_premium` - Filter premium users
- `idx_notifications_log_user_id` - User notification history
- `idx_notifications_log_sent_at` - Time-based queries
- `idx_notifications_log_status` - Failed notification queries
- And more...

### 4. Triggers

**trigger_update_last_token_update**
- Automatically updates `last_token_update` timestamp when `fcm_token` changes
- Helps track stale tokens

### 5. Views

**v_notification_eligible_users**
- Pre-filtered view of users who can receive notifications
- Criteria: `notifications_enabled = true` AND `fcm_token IS NOT NULL`

**v_user_notification_stats**
- Per-user notification statistics
- Shows total, successful, and failed notification counts

**v_campaign_performance**
- Campaign performance metrics
- Shows success rate, send time, and statistics

## Testing the Schema

### Test 1: Insert Test Notification

```sql
-- Insert a test notification
INSERT INTO notifications_log (user_id, notification_type, title, body, status)
VALUES ('test_user_id', 'test', 'Test Notification', 'This is a test', 'sent');

-- Verify
SELECT * FROM notifications_log ORDER BY sent_at DESC LIMIT 1;
```

### Test 2: Update FCM Token (Tests Trigger)

```sql
-- Update a user's FCM token
UPDATE users
SET fcm_token = 'test_fcm_token_12345'
WHERE user_id = 'your_actual_user_id';

-- Check that last_token_update was automatically updated
SELECT user_id, fcm_token, last_token_update
FROM users
WHERE user_id = 'your_actual_user_id';
```

### Test 3: Test User Filtering

```sql
-- Get all notification-eligible users
SELECT * FROM v_notification_eligible_users;

-- Get premium users only
SELECT user_id, email, display_name
FROM users
WHERE is_premium = true
  AND notifications_enabled = true
  AND fcm_token IS NOT NULL;

-- Get users by age (for age-based filtering)
SELECT user_id, email, age
FROM users
WHERE age < 30
  AND notifications_enabled = true
  AND fcm_token IS NOT NULL;
```

### Test 4: Create Test Campaign

```sql
INSERT INTO notification_campaigns (
    campaign_name,
    title,
    body,
    filter_criteria,
    status
) VALUES (
    'Test Campaign',
    'Welcome to Foody!',
    'Start tracking your nutrition today',
    '{"type": "all"}'::jsonb,
    'draft'
);

-- Verify
SELECT * FROM notification_campaigns ORDER BY created_at DESC LIMIT 1;
```

## Troubleshooting

### Issue: Cannot connect to RDS

**Solution:**
1. Check RDS Security Group allows your IP address
2. Verify RDS endpoint is correct
3. Ensure database is publicly accessible (if needed)
4. Check VPC settings

```bash
# Test connection
psql -h your-rds-endpoint.amazonaws.com -p 5432 -U postgres -d foody -c "SELECT 1"
```

### Issue: Permission denied

**Solution:**
Ensure your database user has the required permissions:

```sql
GRANT ALL PRIVILEGES ON DATABASE foody TO your_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_user;
```

### Issue: Column already exists

**Solution:**
The schema uses `ADD COLUMN IF NOT EXISTS`, so this shouldn't happen. If it does, the schema is already deployed. Run the validation script to verify:

```bash
./validate-notification-schema.sh
```

### Issue: Table already exists

**Solution:**
Same as above - the schema uses `CREATE TABLE IF NOT EXISTS`. Verify with validation script.

## Rollback Instructions

If you need to rollback the schema changes:

```sql
-- Drop new tables
DROP TABLE IF EXISTS notifications_log CASCADE;
DROP TABLE IF EXISTS notification_campaigns CASCADE;

-- Drop views
DROP VIEW IF EXISTS v_notification_eligible_users CASCADE;
DROP VIEW IF EXISTS v_user_notification_stats CASCADE;
DROP VIEW IF EXISTS v_campaign_performance CASCADE;

-- Drop trigger
DROP TRIGGER IF EXISTS trigger_update_last_token_update ON users;
DROP FUNCTION IF EXISTS update_last_token_update();

-- Remove columns from users table
ALTER TABLE users DROP COLUMN IF EXISTS fcm_token;
ALTER TABLE users DROP COLUMN IF EXISTS notifications_enabled;
ALTER TABLE users DROP COLUMN IF EXISTS last_token_update;
ALTER TABLE users DROP COLUMN IF EXISTS is_premium;

-- Drop indexes
DROP INDEX IF EXISTS idx_users_fcm_token;
DROP INDEX IF EXISTS idx_users_notifications_enabled;
DROP INDEX IF EXISTS idx_users_is_premium;
-- ... (see schema file for all index names)
```

## Security Best Practices

1. **Never commit database credentials** - Add `.env` to `.gitignore`
2. **Use IAM authentication** - Consider AWS IAM database authentication
3. **Rotate passwords** - Regularly update database passwords
4. **Limit permissions** - Grant only necessary permissions to Lambda roles
5. **Enable SSL** - Use SSL connections to RDS
6. **Monitor access** - Enable CloudWatch logs for database access

## Next Steps

After successful deployment:

1. Mark **Issue #1** as DONE in `PUSH_NOTIFICATION_ISSUES.md`
2. Update issue status on your project board
3. Proceed to **Issue #2: Firebase Admin SDK Setup (Lambda)**
4. Review the Lambda implementation guide in `PUSH_NOTIFICATION.md`

## Support Commands

```bash
# View deployment script help
./deploy-notification-schema.sh --help

# Run validation only (no deployment)
./deploy-notification-schema.sh --verify-only

# View validation script help
./validate-notification-schema.sh --help

# Check PostgreSQL version
psql --version

# Test RDS connectivity
nc -zv your-rds-endpoint.amazonaws.com 5432
```

## Summary

You now have a complete database schema for push notifications with:

- FCM token storage in users table
- Notification logging for analytics
- Campaign management for bulk sends
- User filtering by premium status, age, and preferences
- Performance indexes for fast queries
- Automatic token timestamp updates
- Helper views for common queries

The schema is ready for the Lambda functions to use in the next steps!
