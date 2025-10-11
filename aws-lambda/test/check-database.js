#!/usr/bin/env node

/**
 * Database Health Check Script
 * Tests connection to RDS PostgreSQL and displays database contents
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

async function checkDatabase() {
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected to database successfully!\n');
    
    // Check if tables exist
    console.log('📋 Checking database tables...');
    const tablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    console.log('   Tables:', tablesResult.rows.map(row => row.table_name).join(', '));
    console.log('');
    
    // Check users table columns
    console.log('📊 Users Table Columns:');
    const columnsResult = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);
    console.log('   Columns:', columnsResult.rows.map(col => `${col.column_name} (${col.data_type})`).join(', '));
    console.log('');
    
    // Check users table
    console.log('👥 Users Table:');
    const usersResult = await client.query('SELECT COUNT(*) as user_count FROM users');
    console.log(`   Total users: ${usersResult.rows[0].user_count}`);
    
    // Show recent users (if any)
    if (parseInt(usersResult.rows[0].user_count) > 0) {
      const recentUsers = await client.query(`
        SELECT user_id, email, display_name, created_at, measurement_unit 
        FROM users 
        ORDER BY created_at DESC 
        LIMIT 5
      `);
      console.log('   Recent users:');
      recentUsers.rows.forEach(user => {
        console.log(`     - ${user.display_name || 'No name'} (${user.email})`);
        console.log(`       User ID: ${user.user_id}`);
        console.log(`       Created: ${user.created_at}`);
        console.log(`       Measurement Unit: ${user.measurement_unit || 'Not set'}`);
      });
    } else {
      console.log('   No users found yet');
    }
    console.log('');
    
    // Check foods table
    console.log('🍎 Foods Table:');
    const analysesResult = await client.query('SELECT COUNT(*) as analysis_count FROM foods');
    console.log(`   Total food analyses: ${analysesResult.rows[0].analysis_count}`);
    
    // Show recent food analyses (if any)
    if (parseInt(analysesResult.rows[0].analysis_count) > 0) {
      const recentAnalyses = await client.query(`
        SELECT f.food_name, f.calories, f.health_score, f.analysis_date, u.email
        FROM foods f
        JOIN users u ON f.user_id = u.user_id
        ORDER BY f.created_at DESC 
        LIMIT 5
      `);
      console.log('   Recent food analyses:');
      recentAnalyses.rows.forEach(analysis => {
        console.log(`     - ${analysis.food_name}`);
        console.log(`       Calories: ${analysis.calories}, Health Score: ${analysis.health_score}`);
        console.log(`       User: ${analysis.email}`);
        console.log(`       Date: ${analysis.analysis_date}`);
      });
    } else {
      console.log('   No food analyses found yet');
    }
    
    console.log('\n✅ Database check complete!');
    
  } catch (error) {
    console.error('❌ Database error:', error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

checkDatabase();

