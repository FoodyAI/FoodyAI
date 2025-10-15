// test-local.js
// Local testing script for notification campaigns Lambda function

const { handler } = require('./index');

// Mock event for testing
const createMockEvent = (httpMethod, path = '/campaigns', pathParameters = null, body = null, queryStringParameters = null) => ({
  httpMethod,
  path,
  pathParameters,
  body: body ? JSON.stringify(body) : null,
  queryStringParameters
});

async function testCreateCampaign() {
  console.log('\n🧪 Testing Create Campaign...');
  
  const event = createMockEvent('POST', '/campaigns', null, {
    campaignName: 'Test Campaign',
    title: 'Welcome to Foody!',
    body: 'Start tracking your nutrition today',
    data: {
      screen: '/home',
      type: 'welcome'
    },
    filterCriteria: {
      type: 'all'
    },
    createdBy: 'test-user'
  });

  const result = await handler(event);
  console.log('Result:', JSON.stringify(result, null, 2));
  return result;
}

async function testListCampaigns() {
  console.log('\n🧪 Testing List Campaigns...');
  
  const event = createMockEvent('GET', '/campaigns', null, null, {
    limit: 10,
    offset: 0
  });

  const result = await handler(event);
  console.log('Result:', JSON.stringify(result, null, 2));
  return result;
}

async function testGetCampaign(campaignId) {
  console.log('\n🧪 Testing Get Campaign...');
  
  const event = createMockEvent('GET', `/campaigns/${campaignId}`, { id: campaignId });

  const result = await handler(event);
  console.log('Result:', JSON.stringify(result, null, 2));
  return result;
}

async function testUpdateCampaign(campaignId) {
  console.log('\n🧪 Testing Update Campaign...');
  
  const event = createMockEvent('PUT', `/campaigns/${campaignId}`, { id: campaignId }, {
    title: 'Updated Welcome Message',
    body: 'Updated body content',
    status: 'draft'
  });

  const result = await handler(event);
  console.log('Result:', JSON.stringify(result, null, 2));
  return result;
}

async function testSendCampaign(campaignId) {
  console.log('\n🧪 Testing Send Campaign...');
  
  const event = createMockEvent('POST', `/campaigns/${campaignId}/send`, { id: campaignId });

  const result = await handler(event);
  console.log('Result:', JSON.stringify(result, null, 2));
  return result;
}

async function testDeleteCampaign(campaignId) {
  console.log('\n🧪 Testing Delete Campaign...');
  
  const event = createMockEvent('DELETE', `/campaigns/${campaignId}`, { id: campaignId });

  const result = await handler(event);
  console.log('Result:', JSON.stringify(result, null, 2));
  return result;
}

async function runTests() {
  console.log('🚀 Starting Notification Campaigns Lambda Tests...');
  
  try {
    // Test 1: Create campaign
    const createResult = await testCreateCampaign();
    let campaignId = null;
    
    if (createResult.statusCode === 201) {
      const response = JSON.parse(createResult.body);
      campaignId = response.campaign.id;
      console.log(`✅ Campaign created with ID: ${campaignId}`);
    } else {
      console.log('❌ Failed to create campaign');
      return;
    }

    // Test 2: List campaigns
    await testListCampaigns();

    // Test 3: Get specific campaign
    await testGetCampaign(campaignId);

    // Test 4: Update campaign
    await testUpdateCampaign(campaignId);

    // Test 5: Send campaign
    await testSendCampaign(campaignId);

    // Test 6: Delete campaign
    await testDeleteCampaign(campaignId);

    console.log('\n✅ All tests completed!');

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

// Run tests if this file is executed directly
if (require.main === module) {
  runTests();
}

module.exports = {
  testCreateCampaign,
  testListCampaigns,
  testGetCampaign,
  testUpdateCampaign,
  testSendCampaign,
  testDeleteCampaign,
  runTests
};
