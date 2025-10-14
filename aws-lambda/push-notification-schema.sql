-- ============================================================
-- FOODY PUSH NOTIFICATION DATABASE SCHEMA
-- ============================================================
-- Description: Database schema for Firebase Cloud Messaging (FCM)
--              push notifications with user filtering capabilities
-- Author: Development Team
-- Created: 2025-01-14
-- Version: 1.0.0
-- ============================================================

-- ============================================================
-- STEP 1: ALTER USERS TABLE
-- ============================================================
-- Add FCM token and notification preferences to existing users table

-- Add FCM token column (stores Firebase Cloud Messaging device token)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add notification preferences (allows users to opt in/out of notifications)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true;

-- Add timestamp for tracking when FCM token was last updated
ALTER TABLE users
ADD COLUMN IF NOT EXISTS last_token_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Add premium user flag for filtering premium users
ALTER TABLE users
ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT false;

-- Add comment for documentation
COMMENT ON COLUMN users.fcm_token IS 'Firebase Cloud Messaging device token for push notifications';
COMMENT ON COLUMN users.notifications_enabled IS 'Whether user has enabled push notifications (user preference)';
COMMENT ON COLUMN users.last_token_update IS 'Timestamp of last FCM token update';
COMMENT ON COLUMN users.is_premium IS 'Premium user status for filtered notifications';

-- ============================================================
-- STEP 2: CREATE NOTIFICATIONS LOG TABLE
-- ============================================================
-- Track all sent notifications for analytics and debugging

CREATE TABLE IF NOT EXISTS notifications_log (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- User reference
    user_id VARCHAR(255),

    -- Notification details
    notification_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,

    -- Metadata
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'sent',
    error_message TEXT,

    -- Foreign key constraint
    CONSTRAINT fk_notifications_log_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- Add comments for documentation
COMMENT ON TABLE notifications_log IS 'Log of all push notifications sent to users';
COMMENT ON COLUMN notifications_log.notification_type IS 'Type of notification (manual, campaign, automated, etc.)';
COMMENT ON COLUMN notifications_log.status IS 'Delivery status (sent, delivered, failed, etc.)';
COMMENT ON COLUMN notifications_log.data IS 'Additional JSON data sent with notification';
COMMENT ON COLUMN notifications_log.error_message IS 'Error message if notification failed';

-- ============================================================
-- STEP 3: CREATE NOTIFICATION CAMPAIGNS TABLE
-- ============================================================
-- Manage bulk notification campaigns with scheduling and tracking

CREATE TABLE IF NOT EXISTS notification_campaigns (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Campaign details
    campaign_name VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,

    -- Filtering criteria (stored as JSON for flexibility)
    filter_criteria JSONB DEFAULT '{}'::jsonb,

    -- Scheduling
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,

    -- Status tracking
    status VARCHAR(50) DEFAULT 'draft',

    -- Statistics
    total_recipients INTEGER DEFAULT 0,
    successful_sends INTEGER DEFAULT 0,
    failed_sends INTEGER DEFAULT 0,

    -- Metadata
    created_by VARCHAR(255),
    notes TEXT
);

-- Add comments for documentation
COMMENT ON TABLE notification_campaigns IS 'Bulk notification campaigns with scheduling and tracking';
COMMENT ON COLUMN notification_campaigns.filter_criteria IS 'JSON object defining user filter (type: all|premium|age, etc.)';
COMMENT ON COLUMN notification_campaigns.status IS 'Campaign status (draft, scheduled, sending, sent, failed)';
COMMENT ON COLUMN notification_campaigns.scheduled_at IS 'When campaign should be sent (null = immediate)';
COMMENT ON COLUMN notification_campaigns.sent_at IS 'When campaign was actually sent';

-- ============================================================
-- STEP 4: CREATE INDEXES FOR PERFORMANCE
-- ============================================================

-- Index for quickly finding users by FCM token
CREATE INDEX IF NOT EXISTS idx_users_fcm_token
ON users(fcm_token)
WHERE fcm_token IS NOT NULL;

-- Index for filtering users with notifications enabled
CREATE INDEX IF NOT EXISTS idx_users_notifications_enabled
ON users(notifications_enabled)
WHERE notifications_enabled = true;

-- Index for filtering premium users
CREATE INDEX IF NOT EXISTS idx_users_is_premium
ON users(is_premium)
WHERE is_premium = true;

-- Index for notifications_log by user_id
CREATE INDEX IF NOT EXISTS idx_notifications_log_user_id
ON notifications_log(user_id);

-- Index for notifications_log by sent_at (for time-based queries)
CREATE INDEX IF NOT EXISTS idx_notifications_log_sent_at
ON notifications_log(sent_at DESC);

-- Index for notifications_log by status (for failed notification queries)
CREATE INDEX IF NOT EXISTS idx_notifications_log_status
ON notifications_log(status);

-- Composite index for user notifications history queries
CREATE INDEX IF NOT EXISTS idx_notifications_log_user_sent_at
ON notifications_log(user_id, sent_at DESC);

-- Index for campaign status filtering
CREATE INDEX IF NOT EXISTS idx_notification_campaigns_status
ON notification_campaigns(status);

-- Index for scheduled campaigns
CREATE INDEX IF NOT EXISTS idx_notification_campaigns_scheduled_at
ON notification_campaigns(scheduled_at)
WHERE scheduled_at IS NOT NULL AND status = 'scheduled';

-- ============================================================
-- STEP 5: CREATE TRIGGERS
-- ============================================================

-- Function to update last_token_update timestamp
CREATE OR REPLACE FUNCTION update_last_token_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fcm_token IS DISTINCT FROM OLD.fcm_token THEN
        NEW.last_token_update = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update last_token_update when fcm_token changes
DROP TRIGGER IF EXISTS trigger_update_last_token_update ON users;
CREATE TRIGGER trigger_update_last_token_update
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_last_token_update();

-- ============================================================
-- STEP 6: CREATE HELPER VIEWS (OPTIONAL)
-- ============================================================

-- View for users eligible to receive notifications
CREATE OR REPLACE VIEW v_notification_eligible_users AS
SELECT
    user_id,
    email,
    display_name,
    fcm_token,
    is_premium,
    age,
    notifications_enabled,
    last_token_update
FROM users
WHERE notifications_enabled = true
  AND fcm_token IS NOT NULL;

COMMENT ON VIEW v_notification_eligible_users IS 'Users who can receive push notifications';

-- View for notification statistics by user
CREATE OR REPLACE VIEW v_user_notification_stats AS
SELECT
    u.user_id,
    u.email,
    u.display_name,
    COUNT(nl.id) as total_notifications,
    COUNT(CASE WHEN nl.status = 'sent' THEN 1 END) as successful_notifications,
    COUNT(CASE WHEN nl.status = 'failed' THEN 1 END) as failed_notifications,
    MAX(nl.sent_at) as last_notification_sent
FROM users u
LEFT JOIN notifications_log nl ON u.user_id = nl.user_id
GROUP BY u.user_id, u.email, u.display_name;

COMMENT ON VIEW v_user_notification_stats IS 'Notification statistics per user';

-- View for campaign performance
CREATE OR REPLACE VIEW v_campaign_performance AS
SELECT
    id,
    campaign_name,
    status,
    total_recipients,
    successful_sends,
    failed_sends,
    CASE
        WHEN total_recipients > 0 THEN
            ROUND((successful_sends::numeric / total_recipients::numeric) * 100, 2)
        ELSE 0
    END as success_rate,
    created_at,
    scheduled_at,
    sent_at,
    CASE
        WHEN sent_at IS NOT NULL AND created_at IS NOT NULL THEN
            EXTRACT(EPOCH FROM (sent_at - created_at)) / 60
        ELSE NULL
    END as time_to_send_minutes
FROM notification_campaigns
ORDER BY created_at DESC;

COMMENT ON VIEW v_campaign_performance IS 'Campaign performance metrics and statistics';

-- ============================================================
-- STEP 7: SAMPLE VALIDATION QUERIES
-- ============================================================

-- These queries can be used to validate the schema setup

/*
-- Query 1: Count users with FCM tokens
SELECT COUNT(*) as users_with_fcm_token
FROM users
WHERE fcm_token IS NOT NULL;

-- Query 2: Count users eligible for notifications
SELECT COUNT(*) FROM v_notification_eligible_users;

-- Query 3: Get premium users with notifications enabled
SELECT user_id, email, display_name, fcm_token
FROM users
WHERE is_premium = true
  AND notifications_enabled = true
  AND fcm_token IS NOT NULL;

-- Query 4: Get recent notification logs
SELECT id, user_id, notification_type, title, sent_at, status
FROM notifications_log
ORDER BY sent_at DESC
LIMIT 10;

-- Query 5: Get campaign summary
SELECT id, campaign_name, status, total_recipients, successful_sends, failed_sends
FROM notification_campaigns
ORDER BY created_at DESC
LIMIT 10;

-- Query 6: Get notification statistics by type
SELECT
    notification_type,
    COUNT(*) as total,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as successful,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
FROM notifications_log
GROUP BY notification_type;

-- Query 7: Get users who haven't received notifications in 30 days
SELECT u.user_id, u.email, u.display_name, MAX(nl.sent_at) as last_notification
FROM users u
LEFT JOIN notifications_log nl ON u.user_id = nl.user_id
WHERE u.notifications_enabled = true
  AND u.fcm_token IS NOT NULL
GROUP BY u.user_id, u.email, u.display_name
HAVING MAX(nl.sent_at) < CURRENT_TIMESTAMP - INTERVAL '30 days'
    OR MAX(nl.sent_at) IS NULL;

-- Query 8: Get users by age for filtered notifications
SELECT user_id, email, display_name, age, fcm_token
FROM users
WHERE age < 30
  AND notifications_enabled = true
  AND fcm_token IS NOT NULL;
*/

-- ============================================================
-- STEP 8: GRANT PERMISSIONS (if needed)
-- ============================================================

/*
-- Grant permissions to Lambda execution role (adjust as needed)
GRANT SELECT, INSERT, UPDATE ON users TO lambda_execution_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications_log TO lambda_execution_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON notification_campaigns TO lambda_execution_role;
GRANT SELECT ON v_notification_eligible_users TO lambda_execution_role;
GRANT SELECT ON v_user_notification_stats TO lambda_execution_role;
GRANT SELECT ON v_campaign_performance TO lambda_execution_role;
*/

-- ============================================================
-- COMPLETION MESSAGE
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Push Notification Schema Setup Complete!';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables Created:';
    RAISE NOTICE '  - users (altered with FCM columns)';
    RAISE NOTICE '  - notifications_log';
    RAISE NOTICE '  - notification_campaigns';
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes Created: 10 performance indexes';
    RAISE NOTICE 'Triggers Created: 1 token update trigger';
    RAISE NOTICE 'Views Created: 3 helper views';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Review the schema';
    RAISE NOTICE '  2. Execute this SQL on your RDS database';
    RAISE NOTICE '  3. Verify with sample queries (see bottom of file)';
    RAISE NOTICE '  4. Proceed to Issue #2: Firebase Admin SDK Setup';
END $$;
