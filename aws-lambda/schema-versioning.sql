-- Schema Versioning for Foody App
-- This tracks database schema changes for rollback purposes

-- Create schema version tracking table
CREATE TABLE IF NOT EXISTS schema_versions (
    version INTEGER PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT NOT NULL,
    rollback_sql TEXT
);

-- Insert current stable version
INSERT INTO schema_versions (version, description, rollback_sql) VALUES 
(1, 'Initial schema with integer food IDs', 
 '-- Rollback to integer IDs would require data migration'),
(2, 'Added synced_to_aws column to foods', 
 'ALTER TABLE foods DROP COLUMN synced_to_aws;'),
(3, 'Migrated to UUID-based food IDs (CURRENT STABLE)', 
 '-- This is the current stable version - no rollback needed');

-- Create a function to get current schema version
CREATE OR REPLACE FUNCTION get_current_schema_version()
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT MAX(version) FROM schema_versions);
END;
$$ LANGUAGE plpgsql;

-- Create a function to check if schema is at expected version
CREATE OR REPLACE FUNCTION check_schema_version(expected_version INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    current_version INTEGER;
BEGIN
    SELECT get_current_schema_version() INTO current_version;
    RETURN current_version = expected_version;
END;
$$ LANGUAGE plpgsql;
