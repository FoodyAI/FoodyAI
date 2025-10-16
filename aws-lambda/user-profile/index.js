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
      const { userId, email } = userData;
      
      if (!userId || !email) {
        return {
          statusCode: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          },
          body: JSON.stringify({
            success: false,
            error: 'userId and email are required'
          })
        };
      }
      
      // Check if user exists
      const existingUser = await pool.query(
        'SELECT user_id FROM users WHERE user_id = $1',
        [userId]
      );
      
      if (existingUser.rows.length === 0) {
        // NEW USER: Insert with all provided values
        const query = `
          INSERT INTO users (
            user_id, email, display_name, photo_url, gender, age, weight, height,
            activity_level, goal, daily_calories, bmi, theme_preference, ai_provider,
            measurement_unit, fcm_token, notifications_enabled, is_premium, created_at, updated_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
          RETURNING user_id
        `;

        const values = [
          userId,
          email,
          userData.displayName || null,
          userData.photoUrl || null,
          userData.gender || null,
          userData.age || null,
          userData.weight || null,
          userData.height || null,
          userData.activityLevel || null,
          userData.goal || null,
          userData.dailyCalories || null,
          userData.bmi || null,
          userData.themePreference || 'system',
          userData.aiProvider || 'openai',
          userData.measurementUnit || 'metric',
          userData.fcmToken || null,
          userData.notificationsEnabled !== undefined ? userData.notificationsEnabled : true,
          userData.isPremium !== undefined ? userData.isPremium : false,
          new Date(),
          new Date()
        ];
        
        const result = await pool.query(query, values);
        
        return {
          statusCode: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS'
          },
          body: JSON.stringify({
            success: true,
            userId: result.rows[0].user_id,
            message: 'User profile created successfully'
          })
        };
      } else {
        // EXISTING USER: Only update fields that are provided
        const updateFields = [];
        const updateValues = [];
        let paramIndex = 1;
        
        // Build dynamic UPDATE query based on provided fields
        if (userData.displayName !== undefined) {
          updateFields.push(`display_name = $${paramIndex++}`);
          updateValues.push(userData.displayName);
        }
        if (userData.photoUrl !== undefined) {
          updateFields.push(`photo_url = $${paramIndex++}`);
          updateValues.push(userData.photoUrl);
        }
        if (userData.gender !== undefined) {
          updateFields.push(`gender = $${paramIndex++}`);
          updateValues.push(userData.gender);
        }
        if (userData.age !== undefined) {
          updateFields.push(`age = $${paramIndex++}`);
          updateValues.push(userData.age);
        }
        if (userData.weight !== undefined) {
          updateFields.push(`weight = $${paramIndex++}`);
          updateValues.push(userData.weight);
        }
        if (userData.height !== undefined) {
          updateFields.push(`height = $${paramIndex++}`);
          updateValues.push(userData.height);
        }
        if (userData.activityLevel !== undefined) {
          updateFields.push(`activity_level = $${paramIndex++}`);
          updateValues.push(userData.activityLevel);
        }
        if (userData.goal !== undefined) {
          updateFields.push(`goal = $${paramIndex++}`);
          updateValues.push(userData.goal);
        }
        if (userData.dailyCalories !== undefined) {
          updateFields.push(`daily_calories = $${paramIndex++}`);
          updateValues.push(userData.dailyCalories);
        }
        if (userData.bmi !== undefined) {
          updateFields.push(`bmi = $${paramIndex++}`);
          updateValues.push(userData.bmi);
        }
        if (userData.themePreference !== undefined) {
          updateFields.push(`theme_preference = $${paramIndex++}`);
          updateValues.push(userData.themePreference);
        }
        if (userData.aiProvider !== undefined) {
          updateFields.push(`ai_provider = $${paramIndex++}`);
          updateValues.push(userData.aiProvider);
        }
        if (userData.measurementUnit !== undefined) {
          updateFields.push(`measurement_unit = $${paramIndex++}`);
          updateValues.push(userData.measurementUnit);
        }
        if (userData.fcmToken !== undefined) {
          updateFields.push(`fcm_token = $${paramIndex++}`);
          updateValues.push(userData.fcmToken);
        }
        if (userData.notificationsEnabled !== undefined) {
          updateFields.push(`notifications_enabled = $${paramIndex++}`);
          updateValues.push(userData.notificationsEnabled);
        }
        if (userData.isPremium !== undefined) {
          updateFields.push(`is_premium = $${paramIndex++}`);
          updateValues.push(userData.isPremium);
        }

        // Always update email and timestamp
        updateFields.push(`email = $${paramIndex++}`);
        updateValues.push(email);
        updateFields.push(`updated_at = $${paramIndex++}`);
        updateValues.push(new Date());
        
        // Add userId as the last parameter for WHERE clause
        updateValues.push(userId);
        
        const query = `
          UPDATE users 
          SET ${updateFields.join(', ')}
          WHERE user_id = $${paramIndex}
          RETURNING user_id
        `;
        
        const result = await pool.query(query, updateValues);
        
        return {
          statusCode: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS'
          },
          body: JSON.stringify({
            success: true,
            userId: result.rows[0].user_id,
            message: 'User profile updated successfully'
          })
        };
      }
    } else if (httpMethod === 'DELETE') {
      // Delete user account and all associated data
      const { userId } = pathParameters;
      
      if (!userId) {
        return {
          statusCode: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          },
          body: JSON.stringify({
            success: false,
            error: 'userId is required'
          })
        };
      }
      
      // Check if user exists
      const existingUser = await pool.query(
        'SELECT user_id, email FROM users WHERE user_id = $1',
        [userId]
      );
      
      if (existingUser.rows.length === 0) {
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
      
      const userEmail = existingUser.rows[0].email;
      
      // Delete user (this will cascade delete all food analyses due to foreign key constraint)
      const deleteResult = await pool.query(
        'DELETE FROM users WHERE user_id = $1 RETURNING user_id',
        [userId]
      );
      
      console.log(`User ${userId} (${userEmail}) and all associated data deleted successfully`);
      
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
          'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS'
        },
        body: JSON.stringify({
          success: true,
          message: 'User account and all associated data deleted successfully',
          deletedUserId: deleteResult.rows[0].user_id
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
