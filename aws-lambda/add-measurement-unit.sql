-- Add measurement_unit column to existing users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS measurement_unit VARCHAR(20) DEFAULT 'metric';

-- Update existing users to have default value
UPDATE users 
SET measurement_unit = 'metric' 
WHERE measurement_unit IS NULL;

