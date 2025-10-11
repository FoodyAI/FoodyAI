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
    const { userId, foodId } = JSON.parse(event.body);
    
    if (!userId) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Access-Control-Allow-Methods': 'DELETE,OPTIONS'
        },
        body: JSON.stringify({
          success: false,
          error: 'User ID is required'
        })
      };
    }

    let query, values;
    
    if (foodId) {
      // Delete specific food by ID
      query = `
        DELETE FROM foods 
        WHERE id = $1 AND user_id = $2
        RETURNING id, food_name, user_id
      `;
      values = [foodId, userId];
    } else {
      // Delete all foods for user
      query = `
        DELETE FROM foods 
        WHERE user_id = $1
        RETURNING id, food_name, user_id
      `;
      values = [userId];
    }
    
    const result = await pool.query(query, values);
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'DELETE,OPTIONS'
      },
      body: JSON.stringify({
        success: true,
        deletedCount: result.rows.length,
        deletedFoods: result.rows,
        message: result.rows.length > 0 
          ? `Successfully deleted ${result.rows.length} food record(s)`
          : 'No food records found to delete'
      })
    };
    
  } catch (error) {
    console.error('Error deleting food:', error);
    
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
