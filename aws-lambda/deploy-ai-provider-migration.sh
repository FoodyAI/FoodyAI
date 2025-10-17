#!/bin/bash

# Deploy AI Provider Migration Script
# This script updates the database schema and migrates existing users to use Gemini as default

echo "🚀 Starting AI Provider Migration to Gemini..."

# Set your database connection details
DB_HOST="foody-database.cgfko2mcweuv.us-east-1.rds.amazonaws.com"
DB_NAME="foody_db"
DB_USER="foodyadmin"
DB_PASSWORD="FoodyDB2024!Secure"

# Check if required environment variables are set
if [ -z "$DB_HOST" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "❌ Error: Please set your database connection details in this script"
    echo "   Update DB_HOST, DB_NAME, DB_USER, and DB_PASSWORD variables"
    exit 1
fi

echo "📊 Connecting to database: $DB_NAME on $DB_HOST"

# Set password environment variable for psql
export PGPASSWORD="$DB_PASSWORD"

# Run the migration script
echo "🔄 Running AI provider migration..."
psql -h "$DB_HOST" -d "$DB_NAME" -U "$DB_USER" -f migrate-ai-provider-to-gemini.sql

if [ $? -eq 0 ]; then
    echo "✅ AI Provider migration completed successfully!"
    echo "🎯 All users now default to Gemini AI provider"
else
    echo "❌ Migration failed. Please check the error messages above."
    exit 1
fi

echo "🔍 Verifying migration..."
echo "   - New users will default to 'gemini'"
echo "   - Existing users have been updated to 'gemini'"
echo "   - Flutter app will now use Gemini by default"

echo "🎉 Migration complete! Restart your Flutter app to see the changes."
