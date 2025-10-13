const AWS = require('aws-sdk');

// Configure AWS SDK
const s3 = new AWS.S3({
  region: 'us-east-1'
});

async function deleteSpecificFile() {
  const bucketName = 'foody-images-1759858489';
  const fileName = 'food-image_2025-10-13T06-03-21-765Z_1dbc92e7.jpg';
  
  console.log(`🗑️ Deleting specific file: ${fileName}`);
  console.log(`📦 From bucket: ${bucketName}`);
  
  try {
    // First check if file exists
    try {
      const headResult = await s3.headObject({ 
        Bucket: bucketName, 
        Key: fileName 
      }).promise();
      
      console.log(`✅ File found!`);
      console.log(`📏 Size: ${headResult.ContentLength} bytes`);
      console.log(`📅 Last Modified: ${headResult.LastModified}`);
      
    } catch (headError) {
      if (headError.statusCode === 404) {
        console.log(`ℹ️ File not found (already deleted or never existed)`);
        return;
      } else {
        throw headError;
      }
    }
    
    // Delete the file
    const deleteResult = await s3.deleteObject({
      Bucket: bucketName,
      Key: fileName
    }).promise();
    
    console.log(`✅ File deleted successfully!`);
    console.log(`📊 Delete result:`, deleteResult);
    
  } catch (error) {
    console.error(`❌ Error deleting file:`, error);
  }
}

deleteSpecificFile();
