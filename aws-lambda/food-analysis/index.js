const AWS = require('aws-sdk');
const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');

// Initialize AWS services
const s3 = new AWS.S3();
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

exports.handler = async (event) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS'
  };

  try {
    const httpMethod = event.httpMethod || event.requestContext?.http?.method;
    
    // Handle OPTIONS request for CORS
    if (httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ message: 'CORS preflight successful' })
      };
    }
    
    if (httpMethod === 'GET') {
      // Get all food analyses for a user
      console.log('GET request received for food analyses');
      const userId = event.pathParameters?.userId;
      
      if (!userId) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            success: false,
            error: 'userId is required'
          })
        };
      }
      
      console.log('Fetching food analyses for user:', userId);
      
      const query = `
        SELECT id, user_id, image_url, food_name, calories, protein, carbs, fat, health_score, analysis_date, created_at
        FROM foods
        WHERE user_id = $1
        ORDER BY created_at DESC
      `;
      
      const result = await pool.query(query, [userId]);
      console.log(`Found ${result.rows.length} food analyses for user ${userId}`);
      
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          success: true,
          foods: result.rows,
          count: result.rows.length
        })
      };
      
    } else if (httpMethod === 'POST') {
      // Create food analysis
      console.log('POST request received for food analysis');
      console.log('Event body:', event.body);
      
      const { userId, imageUrl, foodName, calories, protein, carbs, fat, healthScore, foodId, analysisDate } = JSON.parse(event.body);
      
      console.log('Parsed data:', { userId, imageUrl, foodName, calories, protein, carbs, fat, healthScore, foodId, analysisDate });
      
      const query = `
        INSERT INTO foods (id, user_id, image_url, food_name, calories, protein, carbs, fat, health_score, analysis_date)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id
      `;
      
      const values = [
        foodId, // Use UUID from Flutter
        userId,
        imageUrl,
        foodName,
        calories,
        protein,
        carbs,
        fat,
        healthScore,
        analysisDate || new Date().toISOString().split('T')[0] // Use provided date or default to today
      ];
      
      console.log('Executing query with values:', values);
      const result = await pool.query(query, values);
      console.log('Query result:', result.rows);
      
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          success: true,
          foodId: result.rows[0].id,
          message: 'Food analysis saved successfully'
        })
      };
      
    } else if (httpMethod === 'DELETE') {
      // Delete food analysis by unique ID
      const { userId, foodId } = JSON.parse(event.body);
      
      console.log(`Deleting food ID: ${foodId} for user: ${userId}`);
      
      // First, get the food record to extract image URL before deleting
      const getQuery = `
        SELECT id, food_name, image_url 
        FROM foods 
        WHERE user_id = $1 AND id = $2
      `;
      
      const getValues = [userId, foodId];
      const getResult = await pool.query(getQuery, getValues);
      
      if (getResult.rows.length === 0) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({
            success: false,
            error: 'Food analysis not found'
          })
        };
      }
      
      const foodRecord = getResult.rows[0];
      const imageUrl = foodRecord.image_url;
      
      // Delete the S3 image file if it exists
      if (imageUrl && imageUrl.startsWith('s3://')) {
        try {
          // Extract bucket and key from S3 URL (format: s3://bucket/key)
          const s3UrlParts = imageUrl.replace('s3://', '').split('/');
          const bucket = s3UrlParts[0];
          const key = s3UrlParts.slice(1).join('/');
          
          console.log(`Deleting S3 image: bucket=${bucket}, key=${key}`);
          
          const deleteParams = {
            Bucket: bucket,
            Key: key
          };
          
          await s3.deleteObject(deleteParams).promise();
          console.log(`✅ S3 image deleted successfully: ${imageUrl}`);
        } catch (s3Error) {
          console.error(`⚠️ Failed to delete S3 image: ${s3Error.message}`);
          // Continue with database deletion even if S3 deletion fails
        }
      } else if (imageUrl && imageUrl.startsWith('https://')) {
        // Handle public URLs - extract S3 key from the URL
        try {
          const urlParts = imageUrl.split('/');
          const bucketIndex = urlParts.findIndex(part => part.includes('.s3.'));
          if (bucketIndex !== -1) {
            const bucket = urlParts[bucketIndex].split('.')[0];
            const key = urlParts.slice(bucketIndex + 1).join('/');
            
            console.log(`Deleting S3 image from public URL: bucket=${bucket}, key=${key}`);
            
            const deleteParams = {
              Bucket: bucket,
              Key: key
            };
            
            await s3.deleteObject(deleteParams).promise();
            console.log(`✅ S3 image deleted successfully from public URL: ${imageUrl}`);
          }
        } catch (s3Error) {
          console.error(`⚠️ Failed to delete S3 image from public URL: ${s3Error.message}`);
          // Continue with database deletion even if S3 deletion fails
        }
      }
      
      // Now delete the database record
      const deleteQuery = `
        DELETE FROM foods 
        WHERE user_id = $1 AND id = $2
        RETURNING id, food_name
      `;
      
      const deleteValues = [userId, foodId];
      const deleteResult = await pool.query(deleteQuery, deleteValues);
      
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          success: true,
          deletedId: deleteResult.rows[0].id,
          deletedFood: deleteResult.rows[0].food_name,
          deletedImage: imageUrl ? true : false,
          message: 'Food analysis and image deleted successfully'
        })
      };
      
    } else {
      return {
        statusCode: 405,
        headers,
        body: JSON.stringify({
          success: false,
          error: 'Method not allowed'
        })
      };
    }
    
  } catch (error) {
    console.error('Error in food analysis handler:', error);
    console.error('Error stack:', error.stack);
    
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
