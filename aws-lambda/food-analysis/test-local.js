const AWS = require('aws-sdk');
const { Pool } = require('pg');

// Mock AWS S3 for local testing
const mockS3 = {
  deleteObject: (params) => {
    console.log(`🗑️ MOCK S3 DELETE: bucket=${params.Bucket}, key=${params.Key}`);
    return { promise: () => Promise.resolve({}) };
  }
};

// Mock database for local testing
const mockPool = {
  query: async (query, values) => {
    console.log(`📊 MOCK DB QUERY: ${query}`);
    console.log(`📊 MOCK DB VALUES:`, values);
    
    if (query.includes('SELECT id, food_name, image_url')) {
      // Mock response for getting food record
      return {
        rows: [{
          id: 'test-food-id-123',
          food_name: 'Test Grilled Chicken',
          image_url: 's3://foody-images-bucket/food-image_2025-01-12T10-30-00-000Z_abc12345.jpg'
        }]
      };
    } else if (query.includes('DELETE FROM foods')) {
      // Mock response for deleting food record
      return {
        rows: [{
          id: 'test-food-id-123',
          food_name: 'Test Grilled Chicken'
        }]
      };
    }
    
    return { rows: [] };
  }
};

// Test the S3 deletion logic
async function testS3Deletion() {
  console.log('🧪 Testing S3 deletion logic locally...\n');
  
  // Simulate the DELETE request
  const event = {
    httpMethod: 'DELETE',
    body: JSON.stringify({
      userId: 'test-user-123',
      foodId: 'test-food-id-123'
    })
  };
  
  // Mock the Lambda handler logic
  const { userId, foodId } = JSON.parse(event.body);
  
  console.log(`Deleting food ID: ${foodId} for user: ${userId}`);
  
  // First, get the food record to extract image URL before deleting
  const getQuery = `
    SELECT id, food_name, image_url 
    FROM foods 
    WHERE user_id = $1 AND id = $2
  `;
  
  const getValues = [userId, foodId];
  const getResult = await mockPool.query(getQuery, getValues);
  
  if (getResult.rows.length === 0) {
    console.log('❌ Food analysis not found');
    return;
  }
  
  const foodRecord = getResult.rows[0];
  const imageUrl = foodRecord.image_url;
  
  console.log(`📸 Found image URL: ${imageUrl}`);
  
  // Delete the S3 image file if it exists
  if (imageUrl && imageUrl.startsWith('s3://')) {
    try {
      // Extract bucket and key from S3 URL (format: s3://bucket/key)
      const s3UrlParts = imageUrl.replace('s3://', '').split('/');
      const bucket = s3UrlParts[0];
      const key = s3UrlParts.slice(1).join('/');
      
      console.log(`🗑️ Deleting S3 image: bucket=${bucket}, key=${key}`);
      
      const deleteParams = {
        Bucket: bucket,
        Key: key
      };
      
      await mockS3.deleteObject(deleteParams).promise();
      console.log(`✅ S3 image deleted successfully: ${imageUrl}`);
    } catch (s3Error) {
      console.error(`⚠️ Failed to delete S3 image: ${s3Error.message}`);
    }
  } else if (imageUrl && imageUrl.startsWith('https://')) {
    // Handle public URLs - extract S3 key from the URL
    try {
      const urlParts = imageUrl.split('/');
      const bucketIndex = urlParts.findIndex(part => part.includes('.s3.'));
      if (bucketIndex !== -1) {
        const bucket = urlParts[bucketIndex].split('.')[0];
        const key = urlParts.slice(bucketIndex + 1).join('/');
        
        console.log(`🗑️ Deleting S3 image from public URL: bucket=${bucket}, key=${key}`);
        
        const deleteParams = {
          Bucket: bucket,
          Key: key
        };
        
        await mockS3.deleteObject(deleteParams).promise();
        console.log(`✅ S3 image deleted successfully from public URL: ${imageUrl}`);
      }
    } catch (s3Error) {
      console.error(`⚠️ Failed to delete S3 image from public URL: ${s3Error.message}`);
    }
  } else {
    console.log('ℹ️ No image URL found or unsupported format');
  }
  
  // Now delete the database record
  const deleteQuery = `
    DELETE FROM foods 
    WHERE user_id = $1 AND id = $2
    RETURNING id, food_name
  `;
  
  const deleteValues = [userId, foodId];
  const deleteResult = await mockPool.query(deleteQuery, deleteValues);
  
  console.log(`✅ Database record deleted: ${deleteResult.rows[0].food_name}`);
  console.log(`✅ Test completed successfully!`);
}

// Test with different URL formats
async function testDifferentUrlFormats() {
  console.log('\n🧪 Testing different URL formats...\n');
  
  const testUrls = [
    's3://foody-images-bucket/food-image_2025-01-12T10-30-00-000Z_abc12345.jpg',
    'https://foody-images-bucket.s3.us-east-1.amazonaws.com/food-image_2025-01-12T10-30-00-000Z_abc12345.jpg',
    'https://s3.us-east-1.amazonaws.com/foody-images-bucket/food-image_2025-01-12T10-30-00-000Z_abc12345.jpg',
    null,
    'invalid-url'
  ];
  
  for (const imageUrl of testUrls) {
    console.log(`\n📸 Testing URL: ${imageUrl || 'null'}`);
    
    if (imageUrl && imageUrl.startsWith('s3://')) {
      const s3UrlParts = imageUrl.replace('s3://', '').split('/');
      const bucket = s3UrlParts[0];
      const key = s3UrlParts.slice(1).join('/');
      console.log(`✅ S3 format - bucket: ${bucket}, key: ${key}`);
    } else if (imageUrl && imageUrl.startsWith('https://')) {
      const urlParts = imageUrl.split('/');
      const bucketIndex = urlParts.findIndex(part => part.includes('.s3.'));
      if (bucketIndex !== -1) {
        const bucket = urlParts[bucketIndex].split('.')[0];
        const key = urlParts.slice(bucketIndex + 1).join('/');
        console.log(`✅ HTTPS format - bucket: ${bucket}, key: ${key}`);
      } else {
        console.log(`❌ HTTPS format - could not extract bucket/key`);
      }
    } else {
      console.log(`ℹ️ No action needed for: ${imageUrl || 'null'}`);
    }
  }
}

// Run the tests
async function runTests() {
  try {
    await testS3Deletion();
    await testDifferentUrlFormats();
    console.log('\n🎉 All tests completed successfully!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

runTests();
