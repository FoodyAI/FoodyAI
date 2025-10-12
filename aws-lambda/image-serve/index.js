const AWS = require('aws-sdk');

// Initialize AWS S3
const s3 = new AWS.S3();

// Configuration
const S3_BUCKET_NAME = 'foody-images-1759858489';
const S3_REGION = 'us-east-1';

exports.handler = async (event) => {
  const headers = {
    'Content-Type': 'image/jpeg', // Default content type
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,OPTIONS',
    'Cache-Control': 'public, max-age=31536000' // Cache for 1 year
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
    
    if (httpMethod === 'GET') {
      console.log('📥 Image serve request received');
      
      // Extract image key from query parameters
      let imageKey;
      
      // Try to get from query string (e.g., /image-serve?key=imageKey)
      if (event.queryStringParameters && event.queryStringParameters.key) {
        imageKey = event.queryStringParameters.key;
      }
      // Try to get from S3 URL in query string (e.g., /image-serve?s3url=s3://bucket/key)
      else if (event.queryStringParameters && event.queryStringParameters.s3url) {
        const s3Url = event.queryStringParameters.s3url;
        if (s3Url.startsWith('s3://')) {
          // Extract key from s3://bucket/key format
          const urlParts = s3Url.replace('s3://', '').split('/');
          if (urlParts.length >= 2) {
            const bucket = urlParts[0];
            const key = urlParts.slice(1).join('/');
            if (bucket === S3_BUCKET_NAME) {
              imageKey = key;
            } else {
              return {
                statusCode: 400,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  success: false,
                  error: 'Invalid S3 bucket in URL'
                })
              };
            }
          }
        }
      }
      
      if (!imageKey) {
        return {
          statusCode: 400,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            success: false,
            error: 'Image key is required. Use ?key=imageKey or ?s3url=s3://bucket/key'
          })
        };
      }
      
      console.log('🔍 Fetching image with key:', imageKey);
      
      // Get object from S3
      const s3Params = {
        Bucket: S3_BUCKET_NAME,
        Key: imageKey
      };
      
      const s3Object = await s3.getObject(s3Params).promise();
      
      // Determine content type from S3 object metadata or file extension
      let contentType = 'image/jpeg'; // Default
      if (s3Object.ContentType) {
        contentType = s3Object.ContentType;
      } else {
        const extension = imageKey.toLowerCase().split('.').pop();
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg';
        }
      }
      
      // Update headers with correct content type
      headers['Content-Type'] = contentType;
      
      console.log('✅ Successfully fetched image from S3');
      console.log('📊 Content-Type:', contentType);
      console.log('📊 Content-Length:', s3Object.Body.length);
      
      return {
        statusCode: 200,
        headers,
        body: s3Object.Body.toString('base64'),
        isBase64Encoded: true
      };
      
    } else {
      return {
        statusCode: 405,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          success: false,
          error: 'Method not allowed. Only GET requests are supported.'
        })
      };
    }
    
  } catch (error) {
    console.error('❌ Error in image serve handler:', error);
    
    // Handle specific S3 errors
    if (error.code === 'NoSuchKey') {
      return {
        statusCode: 404,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          success: false,
          error: 'Image not found'
        })
      };
    } else if (error.code === 'NoSuchBucket') {
      return {
        statusCode: 500,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          success: false,
          error: 'S3 bucket not found'
        })
      };
    } else if (error.code === 'AccessDenied') {
      return {
        statusCode: 403,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          success: false,
          error: 'Access denied to image'
        })
      };
    }
    
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        success: false,
        error: 'Internal server error',
        details: error.message
      })
    };
  }
};
