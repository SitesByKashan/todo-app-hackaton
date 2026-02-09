-- ============================================================================
-- Complete Database Schema for Phase II Todo Application
-- ============================================================================
-- Created: 2026-02-09
-- Database: Neon PostgreSQL (Serverless)
-- Purpose: Full schema with users and tasks tables for multi-user todo app
-- ============================================================================

-- ============================================================================
-- USERS TABLE
-- ============================================================================
-- Stores user authentication and profile information
-- Managed by Better Auth with JWT tokens

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create unique index on email for fast login lookup
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Create index on created_at for analytics queries
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Add table and column comments
COMMENT ON TABLE users IS 'User accounts with authentication credentials';
COMMENT ON COLUMN users.id IS 'Unique user identifier (UUID from Better Auth)';
COMMENT ON COLUMN users.email IS 'User email address for authentication (unique)';
COMMENT ON COLUMN users.password_hash IS 'Bcrypt-hashed password (never store plain text)';
COMMENT ON COLUMN users.name IS 'User display name (optional)';
COMMENT ON COLUMN users.created_at IS 'Account creation timestamp';
COMMENT ON COLUMN users.updated_at IS 'Last account update timestamp';

-- ============================================================================
-- TASKS TABLE
-- ============================================================================
-- Stores user todo items with completion status

CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Add constraint to limit description length (1000 characters)
ALTER TABLE tasks ADD CONSTRAINT check_description_length
    CHECK (description IS NULL OR LENGTH(description) <= 1000);

-- Add constraint to ensure title is not empty
ALTER TABLE tasks ADD CONSTRAINT check_title_not_empty
    CHECK (LENGTH(TRIM(title)) > 0);

-- Create index on user_id for filtering tasks by user
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);

-- Create composite index on (user_id, completed) for filtered queries
-- Optimizes queries like: SELECT * FROM tasks WHERE user_id = ? AND completed = ?
CREATE INDEX IF NOT EXISTS idx_tasks_user_completed ON tasks(user_id, completed);

-- Add foreign key constraint from tasks.user_id to users.id
-- ON DELETE CASCADE ensures tasks are deleted when user is deleted
ALTER TABLE tasks
ADD CONSTRAINT fk_tasks_user_id
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Add table and column comments
COMMENT ON TABLE tasks IS 'User todo items with completion tracking';
COMMENT ON COLUMN tasks.id IS 'Unique task identifier (auto-increment)';
COMMENT ON COLUMN tasks.user_id IS 'Owner identifier (foreign key to users.id)';
COMMENT ON COLUMN tasks.title IS 'Short description of the task (max 200 chars)';
COMMENT ON COLUMN tasks.description IS 'Detailed information about the task (max 1000 chars, optional)';
COMMENT ON COLUMN tasks.completed IS 'Completion status (true = done, false = pending)';
COMMENT ON COLUMN tasks.created_at IS 'UTC timestamp when task was created';
COMMENT ON COLUMN tasks.updated_at IS 'UTC timestamp when task was last modified';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('users', 'tasks')
ORDER BY table_name;

-- Verify indexes
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('users', 'tasks')
ORDER BY tablename, indexname;

-- Verify foreign key constraints
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
    ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'tasks';

-- ============================================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Insert test user
-- INSERT INTO users (id, email, password_hash, name)
-- VALUES ('test-user-123', 'test@example.com', '$2b$12$...', 'Test User');

-- Insert test tasks
-- INSERT INTO tasks (user_id, title, description, completed) VALUES
-- ('test-user-123', 'Complete Phase II', 'Implement full-stack web application', false),
-- ('test-user-123', 'Deploy to Vercel', 'Deploy frontend and backend', false),
-- ('test-user-123', 'Write documentation', 'Update README with deployment info', true);

-- ============================================================================
-- ROLLBACK (Drop all tables)
-- ============================================================================

-- WARNING: This will delete all data!
-- Uncomment to execute:

-- DROP TABLE IF EXISTS tasks CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;
-- DROP TABLE IF EXISTS schema_migrations CASCADE;
