-- Script khởi tạo cơ sở dữ liệu và bảng chat_history
CREATE DATABASE IF NOT EXISTS chat_history;

-- Chuyển đến cơ sở dữ liệu chat_history
USE chat_history;

-- Tạo bảng chat_history
CREATE TABLE IF NOT EXISTS chat_history (
    id SERIAL PRIMARY KEY,
    user_id STRING NOT NULL,
    message STRING NOT NULL,
    response STRING NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cost FLOAT8 DEFAULT 0.0
);

-- Tạo index để tìm kiếm nhanh hơn theo user_id
CREATE INDEX IF NOT EXISTS idx_chat_history_user_id ON chat_history(user_id);

-- Tạo bảng users nếu chưa tồn tại
CREATE TABLE IF NOT EXISTS users (
    username STRING PRIMARY KEY,
    role STRING NOT NULL DEFAULT 'user'
);

-- Thêm người dùng mặc định
INSERT INTO users (username, role) VALUES ('user1', 'admin') ON CONFLICT (username) DO NOTHING;
INSERT INTO users (username, role) VALUES ('user2', 'user') ON CONFLICT (username) DO NOTHING; 