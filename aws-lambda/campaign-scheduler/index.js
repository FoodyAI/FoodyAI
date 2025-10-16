const { Pool } = require('pg');
const AWS = require('aws-sdk');

// Initialize AWS services
const lambda = new AWS.Lambda({ region: process.env.AWS_REGION || 'us-east-1' });

// Database connection
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
 * Main handler for EventBridge scheduled events
 */
exports.handler = async (event) => {
  try {
    console.log('🕐 Campaign Scheduler: Starting scheduled check...');
    console.log('📅 Event:', JSON.stringify(event, null, 2));

    // Get current time
    const now = new Date();
    console.log('⏰ Current time:', now.toISOString());

    // Find campaigns that are due to be sent
    const dueCampaigns = await getDueCampaigns(now);

    if (dueCampaigns.length === 0) {
      console.log('✅ No campaigns due for sending');
      return {
        statusCode: 200,
        body: JSON.stringify({
          success: true,
          message: 'No campaigns due for sending',
          checkedAt: now.toISOString(),
          dueCampaigns: 0
        })
      };
    }

    console.log(`📤 Found ${dueCampaigns.length} campaigns due for sending`);

    // Send each due campaign
    const results = [];
    for (const campaign of dueCampaigns) {
      try {
        console.log(`🚀 Sending campaign: ${campaign.id} - ${campaign.campaign_name}`);
        
        const result = await sendCampaign(campaign);
        results.push({
          campaignId: campaign.id,
          campaignName: campaign.campaign_name,
          success: true,
          result
        });
        
        console.log(`✅ Campaign sent successfully: ${campaign.id}`);
      } catch (error) {
        console.error(`❌ Failed to send campaign ${campaign.id}:`, error);
        results.push({
          campaignId: campaign.id,
          campaignName: campaign.campaign_name,
          success: false,
          error: error.message
        });
      }
    }

    console.log('🎉 Campaign Scheduler: Completed scheduled check');

    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        message: `Processed ${dueCampaigns.length} campaigns`,
        checkedAt: now.toISOString(),
        results
      })
    };

  } catch (error) {
    console.error('❌ Campaign Scheduler Error:', error);
    
    return {
      statusCode: 500,
      body: JSON.stringify({
        success: false,
        error: 'Campaign scheduler failed',
        message: error.message
      })
    };
  }
};

/**
 * Get campaigns that are due to be sent
 */
async function getDueCampaigns(now) {
  try {
    const query = `
      SELECT id, campaign_name, title, body, data, filter_criteria, created_by
      FROM notification_campaigns 
      WHERE status = 'scheduled' 
        AND scheduled_at IS NOT NULL 
        AND scheduled_at <= $1
      ORDER BY scheduled_at ASC
    `;

    const result = await pool.query(query, [now]);
    console.log(`📊 Found ${result.rows.length} due campaigns`);
    
    return result.rows;
  } catch (error) {
    console.error('❌ Error getting due campaigns:', error);
    throw error;
  }
}

/**
 * Send a campaign by calling the campaign manager Lambda
 */
async function sendCampaign(campaign) {
  try {
    const campaignManagerFunctionName = 'foody-notification-campaigns';
    
    const payload = {
      httpMethod: 'POST',
      pathParameters: { id: campaign.id },
      path: `/campaigns/${campaign.id}/send`,
      body: null
    };

    console.log(`📞 Calling campaign manager for campaign: ${campaign.id}`);

    const params = {
      FunctionName: campaignManagerFunctionName,
      InvocationType: 'RequestResponse',
      Payload: JSON.stringify(payload)
    };

    const response = await lambda.invoke(params).promise();
    
    if (response.StatusCode !== 200) {
      throw new Error(`Lambda invocation failed with status: ${response.StatusCode}`);
    }

    const result = JSON.parse(response.Payload);
    
    if (result.statusCode !== 200) {
      throw new Error(`Campaign send failed: ${result.body}`);
    }

    return JSON.parse(result.body);
  } catch (error) {
    console.error('❌ Error sending campaign:', error);
    throw error;
  }
}
