// send-notification/index.js
// AWS Lambda Function for Sending Push Notifications
// Supports filtered notifications to specific user segments

const { Pool } = require('pg');
const { initializeFirebase } = require('./firebase-admin');
const { sendToDevice, sendToMultipleDevices } = require('./notification-helpers');

// Initialize database connection pool
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: {
    rejectUnauthorized: false
  }
});

// Initialize Firebase Admin SDK
let firebaseInitialized = false;

/**
 * Initialize Firebase if not already initialized
 */
function ensureFirebaseInitialized() {
  if (!firebaseInitialized) {
    initializeFirebase();
    firebaseInitialized = true;
  }
}

/**
 * Main Lambda handler
 */
exports.handler = async (event) => {
  console.log('📩 Send Notification Lambda - Start');
  console.log('📝 Event:', JSON.stringify(event, null, 2));

  try {
    // Initialize Firebase
    ensureFirebaseInitialized();

    const { httpMethod, body } = event;

    // Only accept POST requests
    if (httpMethod !== 'POST') {
      return createResponse(405, {
        success: false,
        error: 'Method not allowed. Use POST.'
      });
    }

    // Parse request body
    const requestData = JSON.parse(body);
    console.log('📝 Request data:', requestData);

    // Validate required fields
    const validation = validateRequest(requestData);
    if (!validation.valid) {
      return createResponse(400, {
        success: false,
        error: validation.error
      });
    }

    const {
      filter,
      notification,
      data = {},
      options = {},
      campaignId = null
    } = requestData;

    // Get target users based on filter
    console.log('🔍 Fetching target users...');
    const targetUsers = await getTargetUsers(filter);

    if (targetUsers.length === 0) {
      console.log('⚠️ No target users found');
      return createResponse(200, {
        success: true,
        message: 'No target users found matching the filter criteria',
        sentCount: 0,
        failedCount: 0
      });
    }

    console.log(`📊 Found ${targetUsers.length} target users`);

    // Send notifications
    const result = await sendNotifications(
      targetUsers,
      notification,
      data,
      options,
      campaignId
    );

    console.log('✅ Send Notification Lambda - Complete');
    return createResponse(200, {
      success: true,
      ...result
    });

  } catch (error) {
    console.error('❌ Error in send notification handler:', error);
    return createResponse(500, {
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
};

/**
 * Validate request data
 */
function validateRequest(data) {
  if (!data.notification) {
    return { valid: false, error: 'notification object is required' };
  }

  if (!data.notification.title || !data.notification.body) {
    return { valid: false, error: 'notification.title and notification.body are required' };
  }

  if (!data.filter) {
    return { valid: false, error: 'filter object is required' };
  }

  if (!data.filter.type) {
    return { valid: false, error: 'filter.type is required (all, premium, age, custom, userIds)' };
  }

  return { valid: true };
}

/**
 * Get target users based on filter criteria
 */
async function getTargetUsers(filter) {
  const { type } = filter;

  console.log(`🔍 Filter type: ${type}`);

  let query = '';
  let params = [];

  switch (type) {
    case 'all':
      // All users with notifications enabled and FCM token
      query = `
        SELECT user_id, fcm_token, email, display_name
        FROM users
        WHERE notifications_enabled = true
          AND fcm_token IS NOT NULL
          AND fcm_token != ''
      `;
      break;

    case 'premium':
      // Premium users only
      query = `
        SELECT user_id, fcm_token, email, display_name
        FROM users
        WHERE notifications_enabled = true
          AND fcm_token IS NOT NULL
          AND fcm_token != ''
          AND is_premium = true
      `;
      break;

    case 'age':
      // Age-based filtering
      const { minAge, maxAge } = filter;

      if (minAge !== undefined && maxAge !== undefined) {
        query = `
          SELECT user_id, fcm_token, email, display_name
          FROM users
          WHERE notifications_enabled = true
            AND fcm_token IS NOT NULL
            AND fcm_token != ''
            AND age >= $1
            AND age <= $2
        `;
        params = [minAge, maxAge];
      } else if (minAge !== undefined) {
        query = `
          SELECT user_id, fcm_token, email, display_name
          FROM users
          WHERE notifications_enabled = true
            AND fcm_token IS NOT NULL
            AND fcm_token != ''
            AND age >= $1
        `;
        params = [minAge];
      } else if (maxAge !== undefined) {
        query = `
          SELECT user_id, fcm_token, email, display_name
          FROM users
          WHERE notifications_enabled = true
            AND fcm_token IS NOT NULL
            AND fcm_token != ''
            AND age <= $1
        `;
        params = [maxAge];
      } else {
        throw new Error('For age filter, provide minAge and/or maxAge');
      }
      break;

    case 'userIds':
      // Specific user IDs
      const { userIds } = filter;

      if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
        throw new Error('userIds array is required and must not be empty');
      }

      // Create placeholders for parameterized query
      const placeholders = userIds.map((_, i) => `$${i + 1}`).join(', ');

      query = `
        SELECT user_id, fcm_token, email, display_name
        FROM users
        WHERE notifications_enabled = true
          AND fcm_token IS NOT NULL
          AND fcm_token != ''
          AND user_id IN (${placeholders})
      `;
      params = userIds;
      break;

    case 'custom':
      // Custom SQL WHERE clause
      const { whereClause } = filter;

      if (!whereClause) {
        throw new Error('whereClause is required for custom filter');
      }

      query = `
        SELECT user_id, fcm_token, email, display_name
        FROM users
        WHERE notifications_enabled = true
          AND fcm_token IS NOT NULL
          AND fcm_token != ''
          AND (${whereClause})
      `;
      break;

    default:
      throw new Error(`Invalid filter type: ${type}. Use: all, premium, age, userIds, or custom`);
  }

  console.log('📝 Query:', query);
  console.log('📝 Params:', params);

  const result = await pool.query(query, params);
  return result.rows;
}

/**
 * Send notifications to target users
 */
async function sendNotifications(targetUsers, notification, data, options, campaignId) {
  const tokens = targetUsers.map(user => user.fcm_token);
  const notificationType = campaignId ? 'campaign' : 'manual';

  console.log(`📤 Sending to ${tokens.length} users...`);

  let sentCount = 0;
  let failedCount = 0;
  const invalidTokens = [];
  const notifications = [];

  try {
    if (tokens.length === 1) {
      // Single device
      try {
        const messageId = await sendToDevice(
          tokens[0],
          notification,
          data,
          options
        );

        console.log(`✅ Sent to user: ${targetUsers[0].user_id}`);
        sentCount++;

        // Log notification
        notifications.push({
          userId: targetUsers[0].user_id,
          status: 'sent',
          errorMessage: null
        });

      } catch (error) {
        console.error(`❌ Failed to send to user: ${targetUsers[0].user_id}`, error.message);
        failedCount++;

        if (error.message === 'INVALID_TOKEN') {
          invalidTokens.push(tokens[0]);
          notifications.push({
            userId: targetUsers[0].user_id,
            status: 'failed',
            errorMessage: 'Invalid or expired token'
          });
        } else {
          notifications.push({
            userId: targetUsers[0].user_id,
            status: 'failed',
            errorMessage: error.message
          });
        }
      }

    } else {
      // Multiple devices - use batch sending
      const batchResult = await sendToMultipleDevices(
        tokens,
        notification,
        data,
        options
      );

      sentCount = batchResult.successCount;
      failedCount = batchResult.failureCount;
      invalidTokens.push(...batchResult.invalidTokens);

      // Log all notifications
      batchResult.responses.forEach((response, index) => {
        const user = targetUsers[index];

        if (response.success) {
          notifications.push({
            userId: user.user_id,
            status: 'sent',
            errorMessage: null
          });
        } else {
          const errorMessage = response.error?.message || 'Unknown error';
          notifications.push({
            userId: user.user_id,
            status: 'failed',
            errorMessage: errorMessage
          });
        }
      });
    }

    // Log all notifications to database
    await logNotifications(notifications, notification, data, notificationType, campaignId);

    // Clear invalid tokens from database
    if (invalidTokens.length > 0) {
      await clearInvalidTokens(invalidTokens);
    }

    console.log(`📊 Notification results:`);
    console.log(`   ✅ Sent: ${sentCount}`);
    console.log(`   ❌ Failed: ${failedCount}`);
    console.log(`   🗑️ Invalid tokens cleared: ${invalidTokens.length}`);

    return {
      sentCount,
      failedCount,
      totalRecipients: targetUsers.length,
      invalidTokensCleared: invalidTokens.length,
      message: `Sent to ${sentCount} users, ${failedCount} failed`
    };

  } catch (error) {
    console.error('❌ Error sending notifications:', error);
    throw error;
  }
}

/**
 * Log notifications to database
 */
async function logNotifications(notifications, notification, data, notificationType, campaignId) {
  if (notifications.length === 0) return;

  try {
    console.log(`📝 Logging ${notifications.length} notifications to database...`);

    // Build batch insert query
    const values = [];
    const placeholders = [];
    let paramIndex = 1;

    notifications.forEach((notif, index) => {
      placeholders.push(
        `($${paramIndex}, $${paramIndex + 1}, $${paramIndex + 2}, $${paramIndex + 3}, $${paramIndex + 4}, $${paramIndex + 5}, $${paramIndex + 6})`
      );

      values.push(
        notif.userId,
        notificationType,
        notification.title,
        notification.body,
        JSON.stringify(data),
        notif.status,
        notif.errorMessage
      );

      paramIndex += 7;
    });

    const query = `
      INSERT INTO notifications_log (
        user_id,
        notification_type,
        title,
        body,
        data,
        status,
        error_message
      ) VALUES ${placeholders.join(', ')}
    `;

    await pool.query(query, values);
    console.log(`✅ Logged ${notifications.length} notifications to database`);

  } catch (error) {
    console.error('❌ Error logging notifications:', error);
    // Don't throw - logging failure shouldn't fail the entire operation
  }
}

/**
 * Clear invalid FCM tokens from database
 */
async function clearInvalidTokens(tokens) {
  if (tokens.length === 0) return;

  try {
    console.log(`🗑️ Clearing ${tokens.length} invalid tokens...`);

    const placeholders = tokens.map((_, i) => `$${i + 1}`).join(', ');

    const query = `
      UPDATE users
      SET fcm_token = NULL
      WHERE fcm_token IN (${placeholders})
    `;

    const result = await pool.query(query, tokens);
    console.log(`✅ Cleared ${result.rowCount} invalid tokens from database`);

  } catch (error) {
    console.error('❌ Error clearing invalid tokens:', error);
    // Don't throw - this is a cleanup operation
  }
}

/**
 * Create HTTP response
 */
function createResponse(statusCode, body) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type,Authorization',
      'Access-Control-Allow-Methods': 'POST,OPTIONS'
    },
    body: JSON.stringify(body)
  };
}
