const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

// Initialize AWS S3
const s3 = new AWS.S3();

// Configuration
const S3_BUCKET_NAME = 'foody-images-1759858489';
const S3_REGION = 'us-east-1';

exports.handler = async (event) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'POST,OPTIONS'
  };

  try {
    const httpMethod = event.httpMethod || event.requestContext?.http?.method;

    // Handle CORS preflight
    if (httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ message: 'CORS preflight successful' })
      };
    }

    if (httpMethod === 'POST') {
      console.log('📤 Image upload request received');
      
      const { imageData, fileName, contentType } = JSON.parse(event.body);

      // Validate required fields
      if (!imageData || !fileName || !contentType) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            success: false,
            error: 'Missing required fields: imageData, fileName, and contentType are required'
          })
        };
      }

      // Decode base64 image data
      const imageBuffer = Buffer.from(imageData, 'base64');
      
      // Generate unique filename with timestamp and UUID
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const fileExtension = fileName.split('.').pop();
      const uniqueId = uuidv4().substring(0, 8);
      const uniqueFileName = `food-image_${timestamp}_${uniqueId}.${fileExtension}`;

      // S3 upload parameters
      const uploadParams = {
        Bucket: S3_BUCKET_NAME,
        Key: uniqueFileName,
        Body: imageBuffer,
        ContentType: contentType,
        Metadata: {
          'original-filename': fileName,
          'upload-timestamp': new Date().toISOString(),
          'upload-source': 'foody-app'
        }
      };

      console.log('📤 Uploading to S3:', {
        bucket: uploadParams.Bucket,
        key: uploadParams.Key,
        contentType: uploadParams.ContentType,
        size: imageBuffer.length
      });

      const s3UploadResult = await s3.upload(uploadParams).promise();

      console.log('✅ S3 upload successful:', s3UploadResult.Location);

      // Return S3 URL in the format: s3://bucket/key
      const s3Url = `s3://${S3_BUCKET_NAME}/${uniqueFileName}`;
      const publicUrl = s3UploadResult.Location;

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          success: true,
          s3Url: s3Url,
          publicUrl: publicUrl,
          fileName: uniqueFileName,
          originalFileName: fileName,
          uploadTimestamp: new Date().toISOString(),
          message: 'Image uploaded to S3 successfully'
        })
      };
    } else {
      return {
        statusCode: 405,
        headers,
        body: JSON.stringify({
          success: false,
          error: 'Method not allowed. Only POST requests are supported.'
        })
      };
    }
  } catch (error) {
    console.error('❌ Error in image upload handler:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        success: false,
        error: 'Internal server error',
        details: error.message
      })
    };
  }
};
