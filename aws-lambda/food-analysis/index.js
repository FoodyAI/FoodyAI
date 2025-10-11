const AWS = require('aws-sdk');
const { Pool } = require('pg');

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
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
  };

  try {
    const httpMethod = event.httpMethod || event.requestContext?.http?.method;
    
    if (httpMethod === 'POST') {
      // Create food analysis
      const { userId, imageUrl, foodName, calories, protein, carbs, fat, healthScore } = JSON.parse(event.body);
      
      const query = `
        INSERT INTO foods (user_id, image_url, food_name, calories, protein, carbs, fat, health_score, analysis_date)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id
      `;
      
      const values = [
        userId,
        imageUrl,
        foodName,
        calories,
        protein,
        carbs,
        fat,
        healthScore,
        new Date()
      ];
      
      const result = await pool.query(query, values);
      
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
      // Delete food analysis
      const { userId, foodName, analysisDate } = JSON.parse(event.body);
      
      console.log(`Deleting food: ${foodName} for user: ${userId} on date: ${analysisDate}`);
      
      const query = `
        DELETE FROM foods 
        WHERE user_id = $1 AND food_name = $2 AND analysis_date = $3
        RETURNING id, food_name
      `;
      
      const values = [userId, foodName, analysisDate];
      const result = await pool.query(query, values);
      
      if (result.rows.length === 0) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({
            success: false,
            error: 'Food analysis not found'
          })
        };
      }
      
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          success: true,
          deletedId: result.rows[0].id,
          deletedFood: result.rows[0].food_name,
          message: 'Food analysis deleted successfully'
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
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        success: false,
        error: 'Internal server error'
      })
    };
  }
};
