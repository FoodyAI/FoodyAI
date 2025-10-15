// notification-helpers.js
// Firebase Cloud Messaging Helper Functions
// Provides utility functions for sending push notifications via FCM

const { getMessaging } = require('./firebase-admin');

/**
 * Send a notification to a single device
 *
 * @param {string} token - FCM device token
 * @param {Object} notification - Notification payload
 * @param {string} notification.title - Notification title
 * @param {string} notification.body - Notification body
 * @param {Object} [data={}] - Optional data payload (key-value pairs)
 * @param {Object} [options={}] - Optional configuration
 * @param {string} [options.imageUrl] - URL for notification image
 * @param {number} [options.badge] - Badge count for iOS
 * @returns {Promise<string>} - Message ID if successful
 * @throws {Error} If sending fails
 *
 * @example
 * await sendToDevice(
 *   'user-fcm-token',
 *   { title: 'Hello!', body: 'Welcome to Foody' },
 *   { action: 'open_home', userId: '123' }
 * );
 */
async function sendToDevice(token, notification, data = {}, options = {}) {
  try {
    console.log(`Sending notification to device: ${token.substring(0, 20)}...`);

    const message = {
      token: token,
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: convertDataToStrings(data),
      // Android specific options
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'default',
          ...(options.imageUrl && { imageUrl: options.imageUrl })
        }
      },
      // iOS specific options
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: options.badge || 1,
            ...(options.imageUrl && { 'mutable-content': 1 })
          }
        },
        ...(options.imageUrl && {
          fcmOptions: {
            imageUrl: options.imageUrl
          }
        })
      }
    };

    const messaging = getMessaging();
    const response = await messaging.send(message);

    console.log(`✓ Successfully sent message: ${response}`);
    return response;

  } catch (error) {
    console.error('Error sending message to device:', error.message);

    // Handle specific error codes
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      console.log(`Invalid or expired token: ${token.substring(0, 20)}...`);
      // Token should be removed from database
      throw new Error('INVALID_TOKEN');
    }

    throw error;
  }
}

/**
 * Send notifications to multiple devices (batch sending)
 *
 * @param {Array<string>} tokens - Array of FCM device tokens (max 500)
 * @param {Object} notification - Notification payload
 * @param {string} notification.title - Notification title
 * @param {string} notification.body - Notification body
 * @param {Object} [data={}] - Optional data payload
 * @param {Object} [options={}] - Optional configuration
 * @returns {Promise<Object>} - Object with successCount, failureCount, and invalidTokens
 *
 * @example
 * const result = await sendToMultipleDevices(
 *   ['token1', 'token2', 'token3'],
 *   { title: 'New Update', body: 'Check out what\'s new!' }
 * );
 * console.log(`Sent to ${result.successCount} devices`);
 */
async function sendToMultipleDevices(tokens, notification, data = {}, options = {}) {
  try {
    // FCM has a limit of 500 tokens per batch
    if (tokens.length > 500) {
      console.warn(`Token count (${tokens.length}) exceeds FCM limit of 500. Splitting into batches...`);
      return await sendInBatches(tokens, notification, data, options);
    }

    console.log(`Sending notification to ${tokens.length} devices...`);

    const message = {
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: convertDataToStrings(data),
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'default',
          ...(options.imageUrl && { imageUrl: options.imageUrl })
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: options.badge || 1
          }
        }
      }
    };

    const messaging = getMessaging();
    const response = await messaging.sendEachForMulticast({
      tokens: tokens,
      notification: message.notification,
      data: message.data,
      android: message.android,
      apns: message.apns
    });

    console.log(`Batch send results:`);
    console.log(`  ✓ Success: ${response.successCount}`);
    console.log(`  ✗ Failure: ${response.failureCount}`);

    // Collect failed/invalid tokens
    const invalidTokens = [];
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          if (errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered') {
            invalidTokens.push(tokens[idx]);
          }
          console.log(`  Error for token ${idx}: ${resp.error?.message}`);
        }
      });
    }

    return {
      successCount: response.successCount,
      failureCount: response.failureCount,
      invalidTokens: invalidTokens,
      responses: response.responses
    };

  } catch (error) {
    console.error('Error sending batch messages:', error.message);
    throw error;
  }
}

/**
 * Send notifications in batches (for more than 500 tokens)
 * Internal helper function
 */
async function sendInBatches(tokens, notification, data, options) {
  const batchSize = 500;
  const batches = [];

  for (let i = 0; i < tokens.length; i += batchSize) {
    batches.push(tokens.slice(i, i + batchSize));
  }

  console.log(`Processing ${batches.length} batches...`);

  const results = {
    successCount: 0,
    failureCount: 0,
    invalidTokens: []
  };

  for (let i = 0; i < batches.length; i++) {
    console.log(`Processing batch ${i + 1}/${batches.length}...`);
    const batchResult = await sendToMultipleDevices(batches[i], notification, data, options);

    results.successCount += batchResult.successCount;
    results.failureCount += batchResult.failureCount;
    results.invalidTokens.push(...batchResult.invalidTokens);

    // Small delay between batches to avoid rate limiting
    if (i < batches.length - 1) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }

  return results;
}

/**
 * Send notification to a topic
 *
 * @param {string} topic - Topic name (without /topics/ prefix)
 * @param {Object} notification - Notification payload
 * @param {Object} [data={}] - Optional data payload
 * @param {Object} [options={}] - Optional configuration
 * @returns {Promise<string>} - Message ID
 *
 * @example
 * await sendToTopic('premium-users', {
 *   title: 'Premium Feature',
 *   body: 'New feature available for premium users!'
 * });
 */
async function sendToTopic(topic, notification, data = {}, options = {}) {
  try {
    console.log(`Sending notification to topic: ${topic}`);

    const message = {
      topic: topic,
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: convertDataToStrings(data),
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'default',
          ...(options.imageUrl && { imageUrl: options.imageUrl })
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: options.badge || 1
          }
        }
      }
    };

    const messaging = getMessaging();
    const response = await messaging.send(message);

    console.log(`✓ Successfully sent message to topic: ${response}`);
    return response;

  } catch (error) {
    console.error(`Error sending message to topic ${topic}:`, error.message);
    throw error;
  }
}

/**
 * Validate an FCM token by attempting a dry-run send
 *
 * @param {string} token - FCM device token
 * @returns {Promise<boolean>} - True if valid, false if invalid
 *
 * @example
 * const isValid = await validateToken(userToken);
 * if (!isValid) {
 *   // Remove token from database
 * }
 */
async function validateToken(token) {
  try {
    const message = {
      token: token,
      notification: {
        title: 'Test',
        body: 'Test'
      }
    };

    const messaging = getMessaging();
    await messaging.send(message, true); // dry_run = true

    return true;
  } catch (error) {
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      return false;
    }
    // For other errors, throw them
    throw error;
  }
}

/**
 * Subscribe tokens to a topic
 *
 * @param {Array<string>} tokens - Array of FCM tokens
 * @param {string} topic - Topic name
 * @returns {Promise<Object>} - Result with success/failure counts
 *
 * @example
 * await subscribeToTopic(['token1', 'token2'], 'premium-users');
 */
async function subscribeToTopic(tokens, topic) {
  try {
    console.log(`Subscribing ${tokens.length} tokens to topic: ${topic}`);

    const messaging = getMessaging();
    const response = await messaging.subscribeToTopic(tokens, topic);

    console.log(`✓ Successfully subscribed ${response.successCount} tokens to topic: ${topic}`);
    if (response.failureCount > 0) {
      console.log(`✗ Failed to subscribe ${response.failureCount} tokens`);
    }

    return response;
  } catch (error) {
    console.error('Error subscribing to topic:', error.message);
    throw error;
  }
}

/**
 * Unsubscribe tokens from a topic
 *
 * @param {Array<string>} tokens - Array of FCM tokens
 * @param {string} topic - Topic name
 * @returns {Promise<Object>} - Result with success/failure counts
 *
 * @example
 * await unsubscribeFromTopic(['token1', 'token2'], 'premium-users');
 */
async function unsubscribeFromTopic(tokens, topic) {
  try {
    console.log(`Unsubscribing ${tokens.length} tokens from topic: ${topic}`);

    const messaging = getMessaging();
    const response = await messaging.unsubscribeFromTopic(tokens, topic);

    console.log(`✓ Successfully unsubscribed ${response.successCount} tokens from topic: ${topic}`);
    if (response.failureCount > 0) {
      console.log(`✗ Failed to unsubscribe ${response.failureCount} tokens`);
    }

    return response;
  } catch (error) {
    console.error('Error unsubscribing from topic:', error.message);
    throw error;
  }
}

/**
 * Convert data object to strings (FCM requires all data values to be strings)
 * Internal helper function
 *
 * @param {Object} data - Data object
 * @returns {Object} - Data object with all values as strings
 */
function convertDataToStrings(data) {
  const result = {};
  for (const [key, value] of Object.entries(data)) {
    result[key] = String(value);
  }
  return result;
}

module.exports = {
  sendToDevice,
  sendToMultipleDevices,
  sendToTopic,
  validateToken,
  subscribeToTopic,
  unsubscribeFromTopic
};
