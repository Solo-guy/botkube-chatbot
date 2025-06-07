-- Create workflows table if it doesn't exist
CREATE TABLE IF NOT EXISTS workflows (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    steps JSONB NOT NULL,
    user_id VARCHAR(100) NOT NULL,
    is_custom BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries by user_id
CREATE INDEX IF NOT EXISTS idx_workflows_user_id ON workflows(user_id);

-- Add constraint to ensure each user's workflow titles are unique
ALTER TABLE workflows DROP CONSTRAINT IF EXISTS unique_workflow_title_per_user;
ALTER TABLE workflows ADD CONSTRAINT unique_workflow_title_per_user UNIQUE (user_id, title); 