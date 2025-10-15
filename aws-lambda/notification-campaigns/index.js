// notification-campaigns/index.js
// AWS Lambda Function for Managing Notification Campaigns
// Provides CRUD operations, scheduling, and campaign management

const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');

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

/**
 * Main Lambda handler
 */
exports.handler = async (event) => {
  console.log('📢 Campaign Manager Lambda - Start');
  console.log('📝 Event:', JSON.stringify(event, null, 2));

  try {
    const { httpMethod, pathParameters, body, queryStringParameters } = event;

    // Route requests based on HTTP method and path
    switch (httpMethod) {
      case 'POST':
        if (pathParameters?.id && event.path.includes('/send')) {
          return await sendCampaign(pathParameters.id);
        } else {
          return await createCampaign(JSON.parse(body || '{}'));
        }

      case 'GET':
        if (pathParameters?.id) {
          return await getCampaign(pathParameters.id);
        } else {
          return await listCampaigns(queryStringParameters || {});
        }

      case 'PUT':
        return await updateCampaign(pathParameters.id, JSON.parse(body || '{}'));

      case 'DELETE':
        return await deleteCampaign(pathParameters.id);

      default:
        return createResponse(405, {
          success: false,
          error: 'Method not allowed'
        });
    }

  } catch (error) {
    console.error('❌ Error in campaign manager handler:', error);
    return createResponse(500, {
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
};

/**
 * Create a new campaign
 */
async function createCampaign(campaignData) {
  try {
    console.log('📝 Creating new campaign:', campaignData);

    const {
      campaignName,
      title,
      body,
      data = {},
      filterCriteria = { type: 'all' },
      scheduledAt = null,
      createdBy = 'system'
    } = campaignData;

    // Validate required fields
    if (!campaignName || !title || !body) {
      return createResponse(400, {
        success: false,
        error: 'campaignName, title, and body are required'
      });
    }

    const campaignId = uuidv4();
    const status = scheduledAt ? 'scheduled' : 'draft';

    const query = `
      INSERT INTO notification_campaigns (
        id, campaign_name, title, body, data, filter_criteria,
        scheduled_at, status, created_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `;

    const values = [
      campaignId,
      campaignName,
      title,
      body,
      JSON.stringify(data),
      JSON.stringify(filterCriteria),
      scheduledAt,
      status,
      createdBy
    ];

    const result = await pool.query(query, values);
    const campaign = result.rows[0];

    console.log('✅ Campaign created successfully:', campaignId);

    return createResponse(201, {
      success: true,
      campaign: formatCampaign(campaign),
      message: 'Campaign created successfully'
    });

  } catch (error) {
    console.error('❌ Error creating campaign:', error);
    throw error;
  }
}

/**
 * Get a specific campaign by ID
 */
async function getCampaign(campaignId) {
  try {
    console.log('📖 Getting campaign:', campaignId);

    const query = `
      SELECT * FROM notification_campaigns 
      WHERE id = $1
    `;

    const result = await pool.query(query, [campaignId]);

    if (result.rows.length === 0) {
      return createResponse(404, {
        success: false,
        error: 'Campaign not found'
      });
    }

    const campaign = result.rows[0];

    return createResponse(200, {
      success: true,
      campaign: formatCampaign(campaign)
    });

  } catch (error) {
    console.error('❌ Error getting campaign:', error);
    throw error;
  }
}

/**
 * List campaigns with optional filtering
 */
async function listCampaigns(queryParams) {
  try {
    console.log('📋 Listing campaigns with params:', queryParams);

    const { status, limit = 50, offset = 0 } = queryParams;
    
    let query = 'SELECT * FROM notification_campaigns';
    let values = [];
    let paramIndex = 1;

    // Add status filter if provided
    if (status) {
      query += ` WHERE status = $${paramIndex}`;
      values.push(status);
      paramIndex++;
    }

    // Add ordering and pagination
    query += ` ORDER BY created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    values.push(parseInt(limit), parseInt(offset));

    const result = await pool.query(query, values);
    const campaigns = result.rows.map(formatCampaign);

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) FROM notification_campaigns';
    let countValues = [];
    
    if (status) {
      countQuery += ' WHERE status = $1';
      countValues.push(status);
    }

    const countResult = await pool.query(countQuery, countValues);
    const totalCount = parseInt(countResult.rows[0].count);

    return createResponse(200, {
      success: true,
      campaigns,
      pagination: {
        total: totalCount,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: (parseInt(offset) + parseInt(limit)) < totalCount
      }
    });

  } catch (error) {
    console.error('❌ Error listing campaigns:', error);
    throw error;
  }
}

/**
 * Update a campaign
 */
async function updateCampaign(campaignId, updateData) {
  try {
    console.log('✏️ Updating campaign:', campaignId, updateData);

    const {
      campaignName,
      title,
      body,
      data,
      filterCriteria,
      scheduledAt,
      status
    } = updateData;

    // First, get the current campaign to check its status
    const currentCampaign = await pool.query(
      'SELECT status, sent_at FROM notification_campaigns WHERE id = $1',
      [campaignId]
    );

    if (currentCampaign.rows.length === 0) {
      return createResponse(404, {
        success: false,
        error: 'Campaign not found'
      });
    }

    const currentStatus = currentCampaign.rows[0].status;
    const sentAt = currentCampaign.rows[0].sent_at;

    // Status validation: Prevent changes to sent campaigns
    if (currentStatus === 'sent' || sentAt !== null) {
      return createResponse(400, {
        success: false,
        error: 'Cannot update a campaign that has already been sent',
        message: 'Sent campaigns are immutable and cannot be modified'
      });
    }

    // Status transition validation
    if (status !== undefined) {
      const validTransitions = {
        'draft': ['scheduled'],
        'scheduled': ['draft', 'sent'],
        'sent': [], // No transitions allowed from sent
        'failed': ['draft', 'scheduled']
      };

      if (!validTransitions[currentStatus]?.includes(status)) {
        return createResponse(400, {
          success: false,
          error: `Invalid status transition from '${currentStatus}' to '${status}'`,
          message: `Valid transitions from '${currentStatus}': ${validTransitions[currentStatus]?.join(', ') || 'none'}`
        });
      }
    }

    // Build dynamic update query
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (campaignName !== undefined) {
      updates.push(`campaign_name = $${paramIndex}`);
      values.push(campaignName);
      paramIndex++;
    }

    if (title !== undefined) {
      updates.push(`title = $${paramIndex}`);
      values.push(title);
      paramIndex++;
    }

    if (body !== undefined) {
      updates.push(`body = $${paramIndex}`);
      values.push(body);
      paramIndex++;
    }

    if (data !== undefined) {
      updates.push(`data = $${paramIndex}`);
      values.push(JSON.stringify(data));
      paramIndex++;
    }

    if (filterCriteria !== undefined) {
      updates.push(`filter_criteria = $${paramIndex}`);
      values.push(JSON.stringify(filterCriteria));
      paramIndex++;
    }

    if (scheduledAt !== undefined) {
      updates.push(`scheduled_at = $${paramIndex}`);
      values.push(scheduledAt);
      paramIndex++;
    }

    if (status !== undefined) {
      updates.push(`status = $${paramIndex}`);
      values.push(status);
      paramIndex++;
    }

    if (updates.length === 0) {
      return createResponse(400, {
        success: false,
        error: 'No fields to update'
      });
    }

    // Note: updated_at column doesn't exist in current schema
    // updates.push(`updated_at = CURRENT_TIMESTAMP`);

    // Add campaign ID to values
    values.push(campaignId);

    const query = `
      UPDATE notification_campaigns 
      SET ${updates.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING *
    `;

    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      return createResponse(404, {
        success: false,
        error: 'Campaign not found'
      });
    }

    const campaign = result.rows[0];

    console.log('✅ Campaign updated successfully:', campaignId);

    return createResponse(200, {
      success: true,
      campaign: formatCampaign(campaign),
      message: 'Campaign updated successfully'
    });

  } catch (error) {
    console.error('❌ Error updating campaign:', error);
    throw error;
  }
}

/**
 * Delete a campaign
 */
async function deleteCampaign(campaignId) {
  try {
    console.log('🗑️ Deleting campaign:', campaignId);

    const query = `
      DELETE FROM notification_campaigns 
      WHERE id = $1
      RETURNING id, campaign_name
    `;

    const result = await pool.query(query, [campaignId]);

    if (result.rows.length === 0) {
      return createResponse(404, {
        success: false,
        error: 'Campaign not found'
      });
    }

    const deletedCampaign = result.rows[0];

    console.log('✅ Campaign deleted successfully:', campaignId);

    return createResponse(200, {
      success: true,
      deletedCampaign,
      message: 'Campaign deleted successfully'
    });

  } catch (error) {
    console.error('❌ Error deleting campaign:', error);
    throw error;
  }
}

/**
 * Send a campaign immediately
 */
async function sendCampaign(campaignId) {
  try {
    console.log('📤 Sending campaign:', campaignId);

    // Get campaign details
    const campaignQuery = `
      SELECT * FROM notification_campaigns 
      WHERE id = $1
    `;

    const campaignResult = await pool.query(campaignQuery, [campaignId]);

    if (campaignResult.rows.length === 0) {
      return createResponse(404, {
        success: false,
        error: 'Campaign not found'
      });
    }

    const campaign = campaignResult.rows[0];

    // Check if campaign can be sent
    if (campaign.status === 'sent') {
      return createResponse(400, {
        success: false,
        error: 'Campaign has already been sent'
      });
    }

    // Update campaign status to 'sending'
    await pool.query(
      'UPDATE notification_campaigns SET status = $1, sent_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['sending', campaignId]
    );

    // Prepare notification payload for send-notification Lambda
    const notificationPayload = {
      filter: campaign.filter_criteria,
      notification: {
        title: campaign.title,
        body: campaign.body
      },
      data: campaign.data,
      campaignId: campaignId
    };

    // Call send-notification Lambda function
    const sendNotificationResult = await callSendNotificationLambda(notificationPayload);

    if (sendNotificationResult.success) {
      // Update campaign with results
      await pool.query(
        `UPDATE notification_campaigns 
         SET status = $1, 
             total_recipients = $2,
             successful_sends = $3,
             failed_sends = $4
         WHERE id = $5`,
        [
          'sent',
          sendNotificationResult.totalRecipients,
          sendNotificationResult.sentCount,
          sendNotificationResult.failedCount,
          campaignId
        ]
      );

      console.log('✅ Campaign sent successfully:', campaignId);

      return createResponse(200, {
        success: true,
        campaignId,
        results: sendNotificationResult,
        message: 'Campaign sent successfully'
      });

    } else {
      // Update campaign status to 'failed'
      await pool.query(
        'UPDATE notification_campaigns SET status = $1 WHERE id = $2',
        ['failed', campaignId]
      );

      return createResponse(500, {
        success: false,
        error: 'Failed to send campaign',
        details: sendNotificationResult.error
      });
    }

  } catch (error) {
    console.error('❌ Error sending campaign:', error);
    
    // Update campaign status to 'failed'
    try {
      await pool.query(
        'UPDATE notification_campaigns SET status = $1 WHERE id = $2',
        ['failed', campaignId]
      );
    } catch (updateError) {
      console.error('❌ Error updating campaign status to failed:', updateError);
    }

    throw error;
  }
}

/**
 * Call the send-notification Lambda function
 */
async function callSendNotificationLambda(payload) {
  try {
    console.log('📞 Calling send-notification Lambda...');

    // For now, we'll use a direct HTTP call to the API Gateway endpoint
    // In production, you might want to use AWS SDK to invoke Lambda directly
    const response = await fetch('https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod/send-notification', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    const result = await response.json();
    
    if (response.ok) {
      return result;
    } else {
      return {
        success: false,
        error: result.error || 'Unknown error'
      };
    }

  } catch (error) {
    console.error('❌ Error calling send-notification Lambda:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Format campaign data for response
 */
function formatCampaign(campaign) {
  return {
    id: campaign.id,
    campaignName: campaign.campaign_name,
    title: campaign.title,
    body: campaign.body,
    data: typeof campaign.data === 'string' ? JSON.parse(campaign.data) : campaign.data,
    filterCriteria: typeof campaign.filter_criteria === 'string' ? JSON.parse(campaign.filter_criteria) : campaign.filter_criteria,
    status: campaign.status,
    scheduledAt: campaign.scheduled_at,
    sentAt: campaign.sent_at,
    createdAt: campaign.created_at,
    updatedAt: campaign.updated_at || campaign.created_at,
    createdBy: campaign.created_by,
    totalRecipients: campaign.total_recipients,
    successfulSends: campaign.successful_sends,
    failedSends: campaign.failed_sends,
    notes: campaign.notes
  };
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
      'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    },
    body: JSON.stringify(body)
  };
}
