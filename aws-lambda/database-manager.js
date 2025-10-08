#!/usr/bin/env node

/**
 * Database Management Script for Foody Developers
 * Allows full database operations for development
 */

const { Client } = require('pg');

const client = new Client({
  host: 'foody-database.cgfko2mcweuv.us-east-1.rds.amazonaws.com',
  user: 'foodyadmin',
  password: 'FoodyDB2024!Secure',
  database: 'foody_db',
  port: 5432,
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
  console.log('🍎 Food Analyses Table:');
  const result = await client.query(`
    SELECT fa.food_name, fa.calories, fa.health_score, fa.analysis_date, u.email
    FROM food_analyses fa
    JOIN users u ON fa.user_id = u.user_id
    ORDER BY fa.created_at DESC
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
    DELETE FROM food_analyses 
    WHERE user_id IN (
      SELECT user_id FROM users 
      WHERE email LIKE '%test%' OR email LIKE '%example.com'
    )
    RETURNING analysis_id, food_name
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
    INSERT INTO food_analyses (
      user_id, image_url, food_name, calories, protein, carbs, fat, 
      health_score, analysis_date, created_at
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING analysis_id, food_name, calories
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
  console.log(`  Analysis ID: ${result.rows[0].analysis_id}, Calories: ${result.rows[0].calories}\n`);
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
  console.log('  node database-manager.js tables          - Show all tables');
  console.log('  node database-manager.js users           - Show all users');
  console.log('  node database-manager.js analyses        - Show all food analyses');
  console.log('  node database-manager.js clear            - Clear test data');
  console.log('  node database-manager.js add-test         - Add test user and analysis');
  console.log('  node database-manager.js query "SELECT..." - Run custom SQL query');
  console.log('  node database-manager.js help            - Show this help');
  console.log('');
  console.log('Examples:');
  console.log('  node database-manager.js query "SELECT COUNT(*) FROM users"');
  console.log('  node database-manager.js query "SELECT * FROM users WHERE age > 20"');
  console.log('  node database-manager.js query "DELETE FROM food_analyses WHERE health_score < 50"');
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
      
    case 'clear':
      await clearTestData();
      break;
      
    case 'add-test':
      const userId = await addTestUser();
      await addTestFoodAnalysis(userId);
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
