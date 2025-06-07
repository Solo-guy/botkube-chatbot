-- Script SQL để cập nhật bảng chat_history với cột bị thiếu

ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS workflow STRING; 