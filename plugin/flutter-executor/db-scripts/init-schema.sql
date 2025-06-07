-- Script SQL để khởi tạo bảng chat_history

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