#!/usr/bin/env node

/**
 * Database Management Script for Foody Developers
 * Allows full database operations for development
 */

const { Client } = require('pg');
require('dotenv').config();

// Validate required environment variables
if (!process.env.DB_HOST || !process.env.DB_USER || !process.env.DB_PASSWORD || !process.env.DB_NAME) {
  console.error('❌ Missing required environment variables:');
  console.error('   DB_HOST, DB_USER, DB_PASSWORD, DB_NAME must be set');
  console.error('   Create a .env file with these variables');
  process.exit(1);
}

const client = new Client({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: parseInt(process.env.DB_PORT) || 5432,
  ssl: {
    rejectUnauthorized: false
  }
});

async function connect() {
  try {
    await client.connect();
    console.log('✅ Connected to database successfully!\n');
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    process.exit(1);
  }
}

async function showTables() {
  console.log('📋 Database Tables:');
  const result = await client.query(`
    SELECT table_name, table_type 
    FROM information_schema.tables 
    WHERE table_schema = 'public'
    ORDER BY table_name
  `);
  
  result.rows.forEach(table => {
    console.log(`  • ${table.table_name} (${table.table_type})`);
  });
  console.log('');
}

async function showUsers() {
  console.log('👥 Users Table:');
  const result = await client.query(`
    SELECT user_id, email, display_name, created_at, measurement_unit
    FROM users 
    ORDER BY created_at DESC
  `);
  
  if (result.rows.length === 0) {
    console.log('  No users found');
  } else {
    result.rows.forEach(user => {
      console.log(`  • ${user.display_name || 'No name'} (${user.email})`);
      console.log(`    User ID: ${user.user_id}`);
      console.log(`    Created: ${user.created_at}`);
      console.log(`    Unit: ${user.measurement_unit || 'Not set'}`);
      console.log('');
    });
  }
}

async function showFoodAnalyses() {
  console.log('🍎 Foods Table:');
  const result = await client.query(`
    SELECT f.food_name, f.calories, f.health_score, f.analysis_date, u.email
    FROM foods f
    JOIN users u ON f.user_id = u.user_id
    ORDER BY f.created_at DESC
  `);
  
  if (result.rows.length === 0) {
    console.log('  No food analyses found');
  } else {
    result.rows.forEach(analysis => {
      console.log(`  • ${analysis.food_name}`);
      console.log(`    Calories: ${analysis.calories}, Health Score: ${analysis.health_score}`);
      console.log(`    User: ${analysis.email}`);
      console.log(`    Date: ${analysis.analysis_date}`);
      console.log('');
    });
  }
}

async function clearTestData() {
  console.log('🧹 Clearing test data...');
  
  // Delete test users (those with test emails)
  const testUsersResult = await client.query(`
    DELETE FROM users 
    WHERE email LIKE '%test%' OR email LIKE '%example.com'
    RETURNING user_id, email
  `);
  
  console.log(`  Deleted ${testUsersResult.rows.length} test users`);
  
  // Delete test food analyses
  const testAnalysesResult = await client.query(`
    DELETE FROM foods 
    WHERE user_id IN (
      SELECT user_id FROM users 
      WHERE email LIKE '%test%' OR email LIKE '%example.com'
    )
    RETURNING id, food_name
  `);
  
  console.log(`  Deleted ${testAnalysesResult.rows.length} test food analyses`);
  console.log('✅ Test data cleared!\n');
}

async function addTestUser() {
  console.log('👤 Adding test user...');
  
  const testUserId = `test-dev-${Date.now()}`;
  const testEmail = `test-dev-${Date.now()}@example.com`;
  
  const result = await client.query(`
    INSERT INTO users (
      user_id, email, display_name, gender, age, weight, height,
      activity_level, goal, daily_calories, bmi, theme_preference, 
      ai_provider, measurement_unit, created_at, updated_at
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
    RETURNING user_id, email, display_name
  `, [
    testUserId,
    testEmail,
    'Test Developer',
    'male',
    25,
    70.0,
    175.0,
    'moderate',
    'maintain',
    2500,
    22.9,
    'system',
    'openai',
    'metric',
    new Date(),
    new Date()
  ]);
  
  console.log(`  ✅ Created test user: ${result.rows[0].display_name} (${result.rows[0].email})`);
  console.log(`  User ID: ${result.rows[0].user_id}\n`);
  
  return result.rows[0].user_id;
}

async function addTestFoodAnalysis(userId) {
  console.log('🍎 Adding test food analysis...');
  
  const result = await client.query(`
    INSERT INTO foods (
      user_id, image_url, food_name, calories, protein, carbs, fat, 
      health_score, analysis_date, created_at
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING id, food_name, calories
  `, [
    userId,
    'https://example.com/test-food.jpg',
    'Test Grilled Chicken',
    350,
    30.0,
    15.0,
    12.0,
    85,
    new Date(),
    new Date()
  ]);
  
  console.log(`  ✅ Created food analysis: ${result.rows[0].food_name}`);
  console.log(`  Food ID: ${result.rows[0].id}, Calories: ${result.rows[0].calories}\n`);
}

async function deleteAllFoods() {
  console.log('🗑️ Deleting all foods...');
  
  const result = await client.query(`
    DELETE FROM foods 
    RETURNING id, food_name, user_id
  `);
  
  console.log(`  ✅ Deleted ${result.rows.length} food records`);
  
  if (result.rows.length > 0) {
    console.log('  Deleted foods:');
    result.rows.forEach(food => {
      console.log(`    - ${food.food_name} (ID: ${food.id}, User: ${food.user_id})`);
    });
  }
  console.log('');
}

async function deleteFoodsByUser(userId) {
  console.log(`🗑️ Deleting foods for user: ${userId}...`);
  
  const result = await client.query(`
    DELETE FROM foods 
    WHERE user_id = $1
    RETURNING id, food_name, user_id
  `, [userId]);
  
  console.log(`  ✅ Deleted ${result.rows.length} food records for user ${userId}`);
  
  if (result.rows.length > 0) {
    console.log('  Deleted foods:');
    result.rows.forEach(food => {
      console.log(`    - ${food.food_name} (ID: ${food.id})`);
    });
  }
  console.log('');
}

async function deleteAllUsers() {
  console.log('🗑️ Deleting all users...');
  console.log('⚠️  This will also delete all associated food analyses (cascade delete)');
  
  // First count users
  const countResult = await client.query('SELECT COUNT(*) FROM users');
  const userCount = countResult.rows[0].count;
  
  console.log(`📊 Found ${userCount} users to delete`);
  
  if (userCount === '0') {
    console.log('✅ No users to delete');
    return;
  }
  
  // Delete all users (cascade deletes foods)
  const result = await client.query(`
    DELETE FROM users 
    RETURNING user_id, email
  `);
  
  console.log(`✅ Deleted ${result.rows.length} users and all their associated data`);
  
  if (result.rows.length > 0 && result.rows.length <= 10) {
    console.log('Deleted users:');
    result.rows.forEach(user => {
      console.log(`  - ${user.email} (ID: ${user.user_id})`);
    });
  } else if (result.rows.length > 10) {
    console.log(`Deleted ${result.rows.length} users (too many to list individually)`);
  }
  console.log('');
}

async function deleteUserById(userId) {
  console.log(`🗑️ Deleting user: ${userId}...`);
  
  // First check if user exists
  const userCheck = await client.query(`
    SELECT user_id, email, display_name 
    FROM users 
    WHERE user_id = $1
  `, [userId]);
  
  if (userCheck.rows.length === 0) {
    console.log(`❌ User with ID ${userId} not found`);
    return;
  }
  
  const user = userCheck.rows[0];
  console.log(`📋 Found user: ${user.display_name || 'No name'} (${user.email})`);
  
  // Count associated foods
  const foodCount = await client.query(`
    SELECT COUNT(*) FROM foods WHERE user_id = $1
  `, [userId]);
  
  console.log(`📊 User has ${foodCount.rows[0].count} food analyses`);
  
  // Delete user (cascade deletes foods)
  const result = await client.query(`
    DELETE FROM users 
    WHERE user_id = $1
    RETURNING user_id, email, display_name
  `, [userId]);
  
  console.log(`✅ Deleted user: ${result.rows[0].display_name || 'No name'} (${result.rows[0].email})`);
  console.log(`✅ Also deleted ${foodCount.rows[0].count} associated food analyses`);
  console.log('');
}

async function deleteUserByEmail(email) {
  console.log(`🗑️ Deleting user by email: ${email}...`);
  
  // First check if user exists
  const userCheck = await client.query(`
    SELECT user_id, email, display_name 
    FROM users 
    WHERE email = $1
  `, [email]);
  
  if (userCheck.rows.length === 0) {
    console.log(`❌ User with email ${email} not found`);
    return;
  }
  
  const user = userCheck.rows[0];
  console.log(`📋 Found user: ${user.display_name || 'No name'} (${user.email})`);
  console.log(`📋 User ID: ${user.user_id}`);
  
  // Count associated foods
  const foodCount = await client.query(`
    SELECT COUNT(*) FROM foods WHERE user_id = $1
  `, [user.user_id]);
  
  console.log(`📊 User has ${foodCount.rows[0].count} food analyses`);
  
  // Delete user (cascade deletes foods)
  const result = await client.query(`
    DELETE FROM users 
    WHERE email = $1
    RETURNING user_id, email, display_name
  `, [email]);
  
  console.log(`✅ Deleted user: ${result.rows[0].display_name || 'No name'} (${result.rows[0].email})`);
  console.log(`✅ Also deleted ${foodCount.rows[0].count} associated food analyses`);
  console.log('');
}

async function deleteUsersByPattern(pattern) {
  console.log(`🗑️ Deleting users matching pattern: ${pattern}...`);
  
  // First find matching users
  const userCheck = await client.query(`
    SELECT user_id, email, display_name 
    FROM users 
    WHERE email LIKE $1 OR display_name LIKE $1
  `, [`%${pattern}%`]);
  
  if (userCheck.rows.length === 0) {
    console.log(`❌ No users found matching pattern: ${pattern}`);
    return;
  }
  
  console.log(`📋 Found ${userCheck.rows.length} users matching pattern:`);
  userCheck.rows.forEach(user => {
    console.log(`  - ${user.display_name || 'No name'} (${user.email}) - ID: ${user.user_id}`);
  });
  
  // Count total associated foods
  const userIds = userCheck.rows.map(u => u.user_id);
  const foodCount = await client.query(`
    SELECT COUNT(*) FROM foods WHERE user_id = ANY($1)
  `, [userIds]);
  
  console.log(`📊 Total food analyses to be deleted: ${foodCount.rows[0].count}`);
  
  // Delete users (cascade deletes foods)
  const result = await client.query(`
    DELETE FROM users 
    WHERE email LIKE $1 OR display_name LIKE $1
    RETURNING user_id, email, display_name
  `, [`%${pattern}%`]);
  
  console.log(`✅ Deleted ${result.rows.length} users and all their associated data`);
  console.log(`✅ Also deleted ${foodCount.rows[0].count} associated food analyses`);
  console.log('');
}

async function showUserDetails(userId) {
  console.log(`👤 User Details for: ${userId}`);
  
  // Get user info
  const userResult = await client.query(`
    SELECT user_id, email, display_name, gender, age, weight, height,
           activity_level, goal, daily_calories, bmi, theme_preference,
           ai_provider, measurement_unit, created_at, updated_at
    FROM users 
    WHERE user_id = $1
  `, [userId]);
  
  if (userResult.rows.length === 0) {
    console.log(`❌ User with ID ${userId} not found`);
    return;
  }
  
  const user = userResult.rows[0];
  console.log(`📋 User Information:`);
  console.log(`  Name: ${user.display_name || 'Not set'}`);
  console.log(`  Email: ${user.email}`);
  console.log(`  Gender: ${user.gender || 'Not set'}`);
  console.log(`  Age: ${user.age || 'Not set'}`);
  console.log(`  Weight: ${user.weight || 'Not set'} kg`);
  console.log(`  Height: ${user.height || 'Not set'} cm`);
  console.log(`  Activity Level: ${user.activity_level || 'Not set'}`);
  console.log(`  Goal: ${user.goal || 'Not set'}`);
  console.log(`  Daily Calories: ${user.daily_calories || 'Not set'}`);
  console.log(`  BMI: ${user.bmi || 'Not set'}`);
  console.log(`  Theme: ${user.theme_preference || 'Not set'}`);
  console.log(`  AI Provider: ${user.ai_provider || 'Not set'}`);
  console.log(`  Unit: ${user.measurement_unit || 'Not set'}`);
  console.log(`  Created: ${user.created_at}`);
  console.log(`  Updated: ${user.updated_at}`);
  
  // Get food analyses count
  const foodCount = await client.query(`
    SELECT COUNT(*) FROM foods WHERE user_id = $1
  `, [userId]);
  
  console.log(`📊 Food Analyses: ${foodCount.rows[0].count}`);
  
  // Get recent food analyses
  const recentFoods = await client.query(`
    SELECT food_name, calories, health_score, analysis_date, created_at
    FROM foods 
    WHERE user_id = $1
    ORDER BY created_at DESC
    LIMIT 5
  `, [userId]);
  
  if (recentFoods.rows.length > 0) {
    console.log(`🍎 Recent Food Analyses (last 5):`);
    recentFoods.rows.forEach(food => {
      console.log(`  - ${food.food_name} (${food.calories} cal, Score: ${food.health_score})`);
      console.log(`    Date: ${food.analysis_date}, Created: ${food.created_at}`);
    });
  }
  console.log('');
}

async function showAllUsersData() {
  console.log('👥 All Users Data Summary:');
  console.log('==========================');
  
  // Get total counts
  const userCount = await client.query('SELECT COUNT(*) FROM users');
  const foodCount = await client.query('SELECT COUNT(*) FROM foods');
  
  console.log(`📊 Total Users: ${userCount.rows[0].count}`);
  console.log(`📊 Total Food Analyses: ${foodCount.rows[0].count}`);
  console.log('');
  
  // Get users with their food counts
  const usersWithData = await client.query(`
    SELECT 
      u.user_id, u.email, u.display_name, u.created_at,
      COUNT(f.id) as food_count,
      MAX(f.created_at) as last_food_analysis
    FROM users u
    LEFT JOIN foods f ON u.user_id = f.user_id
    GROUP BY u.user_id, u.email, u.display_name, u.created_at
    ORDER BY u.created_at DESC
  `);
  
  if (usersWithData.rows.length === 0) {
    console.log('❌ No users found');
    return;
  }
  
  console.log('👤 Users with Data:');
  usersWithData.rows.forEach((user, index) => {
    console.log(`  ${index + 1}. ${user.display_name || 'No name'} (${user.email})`);
    console.log(`     User ID: ${user.user_id}`);
    console.log(`     Food Analyses: ${user.food_count}`);
    console.log(`     Last Analysis: ${user.last_food_analysis || 'Never'}`);
    console.log(`     Created: ${user.created_at}`);
    console.log('');
  });
}

async function showAllFoodAnalyses() {
  console.log('🍎 All Food Analyses:');
  console.log('====================');
  
  const result = await client.query(`
    SELECT 
      f.id, f.food_name, f.calories, f.health_score, f.analysis_date, f.created_at,
      u.email, u.display_name
    FROM foods f
    JOIN users u ON f.user_id = u.user_id
    ORDER BY f.created_at DESC
  `);
  
  if (result.rows.length === 0) {
    console.log('❌ No food analyses found');
    return;
  }
  
  console.log(`📊 Total Food Analyses: ${result.rows.length}`);
  console.log('');
  
  result.rows.forEach((food, index) => {
    console.log(`  ${index + 1}. ${food.food_name}`);
    console.log(`     Calories: ${food.calories}, Health Score: ${food.health_score}`);
    console.log(`     User: ${food.display_name || 'No name'} (${food.email})`);
    console.log(`     Date: ${food.analysis_date}, Created: ${food.created_at}`);
    console.log(`     Food ID: ${food.id}`);
    console.log('');
  });
}

async function showDataStatistics() {
  console.log('📊 Database Statistics:');
  console.log('========================');
  
  // User statistics
  const userStats = await client.query(`
    SELECT 
      COUNT(*) as total_users,
      COUNT(CASE WHEN created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as users_last_7_days,
      COUNT(CASE WHEN created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as users_last_30_days,
      AVG(age) as avg_age,
      AVG(weight) as avg_weight,
      AVG(height) as avg_height,
      AVG(bmi) as avg_bmi
    FROM users
  `);
  
  // Food statistics
  const foodStats = await client.query(`
    SELECT 
      COUNT(*) as total_foods,
      COUNT(CASE WHEN created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as foods_last_7_days,
      COUNT(CASE WHEN created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as foods_last_30_days,
      AVG(calories) as avg_calories,
      AVG(health_score) as avg_health_score,
      MIN(calories) as min_calories,
      MAX(calories) as max_calories
    FROM foods
  `);
  
  // Activity level distribution
  const activityStats = await client.query(`
    SELECT activity_level, COUNT(*) as count
    FROM users 
    WHERE activity_level IS NOT NULL
    GROUP BY activity_level
    ORDER BY count DESC
  `);
  
  // Goal distribution
  const goalStats = await client.query(`
    SELECT goal, COUNT(*) as count
    FROM users 
    WHERE goal IS NOT NULL
    GROUP BY goal
    ORDER BY count DESC
  `);
  
  const user = userStats.rows[0];
  const food = foodStats.rows[0];
  
  console.log('👥 User Statistics:');
  console.log(`  Total Users: ${user.total_users}`);
  console.log(`  New Users (7 days): ${user.users_last_7_days}`);
  console.log(`  New Users (30 days): ${user.users_last_30_days}`);
  console.log(`  Average Age: ${user.avg_age ? Math.round(user.avg_age) : 'N/A'}`);
  console.log(`  Average Weight: ${user.avg_weight ? Math.round(user.avg_weight * 10) / 10 : 'N/A'} kg`);
  console.log(`  Average Height: ${user.avg_height ? Math.round(user.avg_height) : 'N/A'} cm`);
  console.log(`  Average BMI: ${user.avg_bmi ? Math.round(user.avg_bmi * 10) / 10 : 'N/A'}`);
  console.log('');
  
  console.log('🍎 Food Analysis Statistics:');
  console.log(`  Total Analyses: ${food.total_foods}`);
  console.log(`  New Analyses (7 days): ${food.foods_last_7_days}`);
  console.log(`  New Analyses (30 days): ${food.foods_last_30_days}`);
  console.log(`  Average Calories: ${food.avg_calories ? Math.round(food.avg_calories) : 'N/A'}`);
  console.log(`  Average Health Score: ${food.avg_health_score ? Math.round(food.avg_health_score) : 'N/A'}`);
  console.log(`  Calorie Range: ${food.min_calories || 'N/A'} - ${food.max_calories || 'N/A'}`);
  console.log('');
  
  console.log('🏃 Activity Level Distribution:');
  activityStats.rows.forEach(stat => {
    console.log(`  ${stat.activity_level}: ${stat.count} users`);
  });
  console.log('');
  
  console.log('🎯 Goal Distribution:');
  goalStats.rows.forEach(stat => {
    console.log(`  ${stat.goal}: ${stat.count} users`);
  });
  console.log('');
}

async function exportAllData() {
  console.log('📤 Exporting All Data...');
  console.log('========================');
  
  // Export users
  const users = await client.query(`
    SELECT user_id, email, display_name, gender, age, weight, height,
           activity_level, goal, daily_calories, bmi, theme_preference,
           ai_provider, measurement_unit, created_at, updated_at
    FROM users
    ORDER BY created_at DESC
  `);
  
  // Export foods
  const foods = await client.query(`
    SELECT f.id, f.user_id, f.image_url, f.food_name, f.calories, f.protein, f.carbs, f.fat,
           f.health_score, f.analysis_date, f.created_at, f.synced_to_aws,
           u.email, u.display_name
    FROM foods f
    JOIN users u ON f.user_id = u.user_id
    ORDER BY f.created_at DESC
  `);
  
  console.log(`📊 Exported ${users.rows.length} users`);
  console.log(`📊 Exported ${foods.rows.length} food analyses`);
  console.log('');
  
  // Save to files (you can modify this to save to actual files)
  console.log('💾 Data Export Summary:');
  console.log('Users:', JSON.stringify(users.rows, null, 2));
  console.log('');
  console.log('Foods:', JSON.stringify(foods.rows, null, 2));
  console.log('');
}

async function clearAllData() {
  console.log('🗑️ Clearing ALL data from database...');
  console.log('⚠️  WARNING: This will delete ALL users and ALL food analyses!');
  console.log('⚠️  This action cannot be undone!');
  
  // Get counts first
  const userCount = await client.query('SELECT COUNT(*) FROM users');
  const foodCount = await client.query('SELECT COUNT(*) FROM foods');
  
  console.log(`📊 Found ${userCount.rows[0].count} users and ${foodCount.rows[0].count} food analyses`);
  
  if (userCount.rows[0].count === '0' && foodCount.rows[0].count === '0') {
    console.log('✅ Database is already empty');
    return;
  }
  
  // Delete all foods first (to avoid foreign key issues)
  await client.query('DELETE FROM foods');
  console.log('✅ Deleted all food analyses');
  
  // Delete all users
  await client.query('DELETE FROM users');
  console.log('✅ Deleted all users');
  
  console.log('✅ Database completely cleared!');
  console.log('');
}

async function runCustomQuery(query) {
  console.log('🔍 Running custom query...');
  console.log(`Query: ${query}\n`);
  
  try {
    const result = await client.query(query);
    console.log(`✅ Query executed successfully!`);
    console.log(`Rows affected: ${result.rowCount}`);
    
    if (result.rows.length > 0) {
      console.log('\nResults:');
      console.table(result.rows);
    }
  } catch (error) {
    console.error('❌ Query failed:', error.message);
  }
  console.log('');
}

async function showHelp() {
  console.log('🛠️  Database Manager Commands:');
  console.log('================================');
  console.log('');
  console.log('📊 VIEW COMMANDS:');
  console.log('  node database-manager.js tables          - Show all tables');
  console.log('  node database-manager.js users           - Show all users');
  console.log('  node database-manager.js analyses        - Show all food analyses');
  console.log('  node database-manager.js user-details <user_id> - Show detailed user info');
  console.log('  node database-manager.js all-users-data  - Show all users with data summary');
  console.log('  node database-manager.js all-foods        - Show all food analyses with user info');
  console.log('  node database-manager.js stats           - Show comprehensive database statistics');
  console.log('');
  console.log('🧪 TEST COMMANDS:');
  console.log('  node database-manager.js clear            - Clear test data');
  console.log('  node database-manager.js add-test         - Add test user and analysis');
  console.log('');
  console.log('🗑️ DELETE COMMANDS:');
  console.log('  node database-manager.js delete-foods     - Delete all foods');
  console.log('  node database-manager.js delete-users     - Delete all users');
  console.log('  node database-manager.js delete-user-foods <user_id> - Delete foods for specific user');
  console.log('  node database-manager.js delete-user <user_id> - Delete specific user by ID');
  console.log('  node database-manager.js delete-user-email <email> - Delete specific user by email');
  console.log('  node database-manager.js delete-users-pattern <pattern> - Delete users matching pattern');
  console.log('  node database-manager.js clear-all        - Clear ALL data (users + foods)');
  console.log('');
  console.log('📤 EXPORT COMMANDS:');
  console.log('  node database-manager.js export-all      - Export all users and foods data');
  console.log('');
  console.log('🔍 QUERY COMMANDS:');
  console.log('  node database-manager.js query "SELECT..." - Run custom SQL query');
  console.log('  node database-manager.js help            - Show this help');
  console.log('');
  console.log('Examples:');
  console.log('  node database-manager.js stats            - Get comprehensive statistics');
  console.log('  node database-manager.js all-users-data   - See all users with their data counts');
  console.log('  node database-manager.js all-foods       - See all food analyses');
  console.log('  node database-manager.js export-all     - Export all data as JSON');
  console.log('  node database-manager.js clear-all       - WARNING: Delete everything!');
  console.log('  node database-manager.js query "SELECT COUNT(*) FROM users"');
  console.log('  node database-manager.js query "SELECT * FROM users WHERE age > 20"');
  console.log('  node database-manager.js query "DELETE FROM foods WHERE health_score < 50"');
  console.log('  node database-manager.js delete-user-foods "ALdvN6kkPQfEdAIyb62dPAnNQIQ2"');
  console.log('  node database-manager.js delete-user "ALdvN6kkPQfEdAIyb62dPAnNQIQ2"');
  console.log('  node database-manager.js delete-user-email "user@example.com"');
  console.log('  node database-manager.js delete-users-pattern "test"');
  console.log('  node database-manager.js user-details "ALdvN6kkPQfEdAIyb62dPAnNQIQ2"');
  console.log('');
}

async function main() {
  const command = process.argv[2];
  
  await connect();
  
  switch (command) {
    case 'tables':
      await showTables();
      break;
      
    case 'users':
      await showUsers();
      break;
      
    case 'analyses':
      await showFoodAnalyses();
      break;
      
    case 'user-details':
      const detailsUserId = process.argv[3];
      if (!detailsUserId) {
        console.error('❌ Please provide a user ID');
        process.exit(1);
      }
      await showUserDetails(detailsUserId);
      break;
      
    case 'all-users-data':
      await showAllUsersData();
      break;
      
    case 'all-foods':
      await showAllFoodAnalyses();
      break;
      
    case 'stats':
      await showDataStatistics();
      break;
      
    case 'clear':
      await clearTestData();
      break;
      
    case 'add-test':
      const userId = await addTestUser();
      await addTestFoodAnalysis(userId);
      break;
      
    case 'delete-foods':
      await deleteAllFoods();
      break;
      
    case 'delete-users':
      await deleteAllUsers();
      break;
      
    case 'delete-user-foods':
      const targetUserId = process.argv[3];
      if (!targetUserId) {
        console.error('❌ Please provide a user ID');
        process.exit(1);
      }
      await deleteFoodsByUser(targetUserId);
      break;
      
    case 'delete-user':
      const deleteUserId = process.argv[3];
      if (!deleteUserId) {
        console.error('❌ Please provide a user ID');
        process.exit(1);
      }
      await deleteUserById(deleteUserId);
      break;
      
    case 'delete-user-email':
      const deleteEmail = process.argv[3];
      if (!deleteEmail) {
        console.error('❌ Please provide an email address');
        process.exit(1);
      }
      await deleteUserByEmail(deleteEmail);
      break;
      
    case 'delete-users-pattern':
      const pattern = process.argv[3];
      if (!pattern) {
        console.error('❌ Please provide a search pattern');
        process.exit(1);
      }
      await deleteUsersByPattern(pattern);
      break;
      
    case 'clear-all':
      await clearAllData();
      break;
      
    case 'export-all':
      await exportAllData();
      break;
      
    case 'query':
      const query = process.argv[3];
      if (!query) {
        console.error('❌ Please provide a SQL query');
        process.exit(1);
      }
      await runCustomQuery(query);
      break;
      
    case 'help':
    default:
      await showHelp();
      break;
  }
  
  await client.end();
}

main().catch(console.error);
