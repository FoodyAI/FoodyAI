const AWS = require('aws-sdk');
const { Pool } = require('pg');

// Initialize AWS services
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
    const { httpMethod, pathParameters, body } = event;
    
    if (httpMethod === 'GET') {
      // Get user profile
      const { userId } = pathParameters;
      const query = 'SELECT * FROM users WHERE user_id = $1';
      const result = await pool.query(query, [userId]);
      
      if (result.rows.length === 0) {
        return {
          statusCode: 404,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          },
          body: JSON.stringify({
            success: false,
            error: 'User not found'
          })
        };
      }
      
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          success: true,
          user: result.rows[0]
        })
      };
      
    } else if (httpMethod === 'POST') {
      // Create or update user profile
      const userData = JSON.parse(body);
      const {
        userId,
        email,
        displayName,
        photoUrl,
        gender,
        age,
        weight,
        height,
        activityLevel,
        goal,
        dailyCalories,
        bmi,
        themePreference,
        aiProvider
      } = userData;
      
      const query = `
        INSERT INTO users (
          user_id, email, display_name, photo_url, gender, age, weight, height,
          activity_level, goal, daily_calories, bmi, theme_preference, ai_provider, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
        ON CONFLICT (user_id) DO UPDATE SET
          email = EXCLUDED.email,
          display_name = EXCLUDED.display_name,
          photo_url = EXCLUDED.photo_url,
          gender = EXCLUDED.gender,
          age = EXCLUDED.age,
          weight = EXCLUDED.weight,
          height = EXCLUDED.height,
          activity_level = EXCLUDED.activity_level,
          goal = EXCLUDED.goal,
          daily_calories = EXCLUDED.daily_calories,
          bmi = EXCLUDED.bmi,
          theme_preference = EXCLUDED.theme_preference,
          ai_provider = EXCLUDED.ai_provider,
          updated_at = EXCLUDED.updated_at
        RETURNING user_id
      `;
      
      const values = [
        userId, email, displayName, photoUrl, gender, age, weight, height,
        activityLevel, goal, dailyCalories, bmi, themePreference, aiProvider,
        new Date(), new Date()
      ];
      
      const result = await pool.query(query, values);
      
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        },
        body: JSON.stringify({
          success: true,
          userId: result.rows[0].user_id,
          message: 'User profile saved successfully'
        })
      };
    }
    
    return {
      statusCode: 405,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        success: false,
        error: 'Method not allowed'
      })
    };
    
  } catch (error) {
    console.error('Error in user profile handler:', error);
    
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
