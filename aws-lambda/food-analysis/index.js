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
  try {
    const { userId, imageUrl, foodName, calories, protein, carbs, fat, healthScore } = JSON.parse(event.body);
    
    // Store food analysis in database
    const query = `
      INSERT INTO food_analyses (user_id, image_url, food_name, calories, protein, carbs, fat, health_score, analysis_date)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING analysis_id
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
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
      },
      body: JSON.stringify({
        success: true,
        analysisId: result.rows[0].analysis_id,
        message: 'Food analysis saved successfully'
      })
    };
    
  } catch (error) {
    console.error('Error saving food analysis:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        success: false,
        error: 'Internal server error'
      })
    };
  }
};
