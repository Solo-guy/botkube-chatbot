-- Query to check the schema of the chat_history table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'chat_history'
ORDER BY ordinal_position;

-- Query to check the number of rows in the chat_history table
SELECT COUNT(*) FROM chat_history; 