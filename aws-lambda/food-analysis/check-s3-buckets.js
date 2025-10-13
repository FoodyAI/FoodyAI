const AWS = require('aws-sdk');

// Configure AWS SDK
const s3 = new AWS.S3({
  region: 'us-east-1'
});

async function listS3Buckets() {
  console.log('🔍 Listing all S3 buckets...');
  
  try {
    const result = await s3.listBuckets().promise();
    console.log(`📦 Found ${result.Buckets.length} buckets:`);
    
    for (const bucket of result.Buckets) {
      console.log(`  - ${bucket.Name} (created: ${bucket.CreationDate})`);
    }
    
    return result.Buckets.map(b => b.Name);
  } catch (error) {
    console.error('❌ Error listing buckets:', error);
    return [];
  }
}

async function searchForImageInBuckets(bucketNames) {
  const targetKey = 'food-image_2025-10-13T06-22-19-511Z_7527af83.jpg';
  
  console.log(`\n🔍 Searching for image: ${targetKey}`);
  
  for (const bucketName of bucketNames) {
    try {
      console.log(`\n📦 Checking bucket: ${bucketName}`);
      
      // List objects in the bucket
      const listParams = {
        Bucket: bucketName,
        MaxKeys: 1000 // Adjust if you have more than 1000 objects
      };
      
      const objects = await s3.listObjectsV2(listParams).promise();
      console.log(`  📊 Found ${objects.Contents.length} objects in bucket`);
      
      // Look for the specific file
      const targetFile = objects.Contents.find(obj => obj.Key === targetKey);
      if (targetFile) {
        console.log(`  ✅ FOUND TARGET FILE!`);
        console.log(`  📸 Key: ${targetFile.Key}`);
        console.log(`  📏 Size: ${targetFile.Size} bytes`);
        console.log(`  📅 Last Modified: ${targetFile.LastModified}`);
        
        // Delete the file
        console.log(`  🗑️ Deleting file...`);
        const deleteResult = await s3.deleteObject({
          Bucket: bucketName,
          Key: targetKey
        }).promise();
        
        console.log(`  ✅ File deleted successfully!`);
        console.log(`  📊 Delete result:`, deleteResult);
        return true;
      } else {
        console.log(`  ℹ️ Target file not found in this bucket`);
        
        // Show some sample files for debugging
        if (objects.Contents.length > 0) {
          console.log(`  📋 Sample files in bucket:`);
          objects.Contents.slice(0, 5).forEach(obj => {
            console.log(`    - ${obj.Key}`);
          });
          if (objects.Contents.length > 5) {
            console.log(`    ... and ${objects.Contents.length - 5} more files`);
          }
        }
      }
    } catch (error) {
      console.error(`  ❌ Error checking bucket ${bucketName}:`, error.message);
    }
  }
  
  return false;
}

async function searchForFoodImages(bucketNames) {
  console.log(`\n🔍 Searching for any food images...`);
  
  for (const bucketName of bucketNames) {
    try {
      console.log(`\n📦 Checking bucket: ${bucketName}`);
      
      // List objects with prefix filter
      const listParams = {
        Bucket: bucketName,
        Prefix: 'food-image_',
        MaxKeys: 100
      };
      
      const objects = await s3.listObjectsV2(listParams).promise();
      console.log(`  📊 Found ${objects.Contents.length} food images in bucket`);
      
      if (objects.Contents.length > 0) {
        console.log(`  📋 Food images found:`);
        objects.Contents.forEach(obj => {
          console.log(`    - ${obj.Key} (${obj.Size} bytes)`);
        });
      }
    } catch (error) {
      console.error(`  ❌ Error checking bucket ${bucketName}:`, error.message);
    }
  }
}

async function runCheck() {
  try {
    const bucketNames = await listS3Buckets();
    
    if (bucketNames.length === 0) {
      console.log('❌ No S3 buckets found or AWS credentials not configured');
      return;
    }
    
    const found = await searchForImageInBuckets(bucketNames);
    
    if (!found) {
      await searchForFoodImages(bucketNames);
    }
    
  } catch (error) {
    console.error('❌ Check failed:', error);
  }
}

runCheck();
