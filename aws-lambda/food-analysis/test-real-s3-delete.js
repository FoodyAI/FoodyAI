const AWS = require('aws-sdk');

// Configure AWS SDK
const s3 = new AWS.S3({
  region: 'us-east-1' // Make sure this matches your S3 bucket region
});

async function deleteRealS3File() {
  const imageUrl = 's3://foody-images-bucket/food-image_2025-10-13T06-22-19-511Z_7527af83.jpg';
  
  console.log('🧪 Testing REAL S3 deletion...');
  console.log(`📸 Image URL: ${imageUrl}`);
  
  try {
    // Extract bucket and key from S3 URL
    const s3UrlParts = imageUrl.replace('s3://', '').split('/');
    const bucket = s3UrlParts[0];
    const key = s3UrlParts.slice(1).join('/');
    
    console.log(`🗑️ Deleting from S3: bucket=${bucket}, key=${key}`);
    
    // First, check if the file exists
    try {
      await s3.headObject({ Bucket: bucket, Key: key }).promise();
      console.log('✅ File exists in S3, proceeding with deletion...');
    } catch (headError) {
      if (headError.statusCode === 404) {
        console.log('ℹ️ File not found in S3 (already deleted or never existed)');
        return;
      } else {
        throw headError;
      }
    }
    
    // Delete the file
    const deleteParams = {
      Bucket: bucket,
      Key: key
    };
    
    const result = await s3.deleteObject(deleteParams).promise();
    console.log('✅ S3 file deleted successfully!');
    console.log('📊 Delete result:', result);
    
  } catch (error) {
    console.error('❌ Error deleting S3 file:', error);
    
    if (error.code === 'NoSuchBucket') {
      console.error('❌ Bucket does not exist');
    } else if (error.code === 'NoSuchKey') {
      console.error('❌ File does not exist in S3');
    } else if (error.code === 'AccessDenied') {
      console.error('❌ Access denied - check AWS credentials and permissions');
    } else {
      console.error('❌ Unknown error:', error.message);
    }
  }
}

// Also test with different bucket names in case the bucket name is different
async function testDifferentBuckets() {
  const possibleBuckets = [
    'foody-images-bucket',
    'foody-app-images',
    'foody-s3-bucket',
    'foody-images',
    'foody-app-bucket'
  ];
  
  const key = 'food-image_2025-10-13T06-22-19-511Z_7527af83.jpg';
  
  console.log('\n🔍 Checking different possible bucket names...');
  
  for (const bucket of possibleBuckets) {
    try {
      console.log(`\n📦 Checking bucket: ${bucket}`);
      await s3.headObject({ Bucket: bucket, Key: key }).promise();
      console.log(`✅ Found file in bucket: ${bucket}`);
      
      // Delete from this bucket
      const deleteParams = { Bucket: bucket, Key: key };
      await s3.deleteObject(deleteParams).promise();
      console.log(`✅ Deleted file from bucket: ${bucket}`);
      return; // Found and deleted, no need to check other buckets
      
    } catch (error) {
      if (error.statusCode === 404) {
        console.log(`ℹ️ File not found in bucket: ${bucket}`);
      } else if (error.code === 'NoSuchBucket') {
        console.log(`ℹ️ Bucket does not exist: ${bucket}`);
      } else {
        console.log(`⚠️ Error checking bucket ${bucket}:`, error.message);
      }
    }
  }
  
  console.log('\n❌ File not found in any of the checked buckets');
}

// Run the test
async function runTest() {
  try {
    await deleteRealS3File();
    await testDifferentBuckets();
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

runTest();
