-- Script SQL để cập nhật bảng chat_history với các cột bị thiếu

ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS event_type STRING;
ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS resource STRING; 