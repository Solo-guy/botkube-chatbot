-- Script SQL để cập nhật cấu trúc bảng chat_history

-- Thêm cột user_id nếu chưa có
ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS user_id STRING;

-- Thêm cột message nếu chưa có
ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS message STRING;

-- Thêm cột cost nếu chưa có
ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS cost FLOAT8 DEFAULT 0.0;

-- Cập nhật lại tên cột nếu đang sử dụng tên khác
-- Có thể cần chạy trong một phiên riêng biệt
-- ALTER TABLE chat_history RENAME COLUMN "resource" TO "user_id" IF EXISTS;
-- ALTER TABLE chat_history RENAME COLUMN "name" TO "message" IF EXISTS; 