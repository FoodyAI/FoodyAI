-- Migration script to update existing users from OpenAI to Gemini as default AI provider
-- Run this script to update existing users who have 'openai' as their ai_provider

-- Update all users who currently have 'openai' as their AI provider to 'gemini'
UPDATE users 
SET ai_provider = 'gemini', 
    updated_at = CURRENT_TIMESTAMP 
WHERE ai_provider = 'openai';

-- Verify the update
SELECT user_id, email, ai_provider, updated_at 
FROM users 
WHERE ai_provider = 'gemini' 
ORDER BY updated_at DESC 
LIMIT 10;

-- Show count of updated users
SELECT COUNT(*) as updated_users_count 
FROM users 
WHERE ai_provider = 'gemini';
