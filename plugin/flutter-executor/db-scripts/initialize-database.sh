#!/bin/bash

# Thông tin kết nối cơ sở dữ liệu
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-26257}
DB_USER=${DB_USER:-"root"}
DB_PASSWORD=${DB_PASSWORD:-""}
DB_NAME=${DB_NAME:-"chat_history"}

echo "Đang khởi tạo cơ sở dữ liệu: $DB_NAME"

# Tạo database
psql postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT -c "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
if [ $? -ne 0 ]; then
  echo "Lỗi khi tạo database. Kiểm tra kết nối đến CockroachDB."
  exit 1
fi

# Chạy script khởi tạo bảng
echo "Đang khởi tạo các bảng trong cơ sở dữ liệu $DB_NAME..."
psql postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME -f ./db-scripts/init-schema.sql
if [ $? -ne 0 ]; then
  echo "Lỗi khi khởi tạo bảng. Kiểm tra file SQL."
  exit 1
fi

# Thêm người dùng mặc định
echo "Đang thêm người dùng mặc định..."
psql postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME -c "INSERT INTO users (username, role) VALUES ('user1', 'admin'), ('user2', 'user') ON CONFLICT (username) DO NOTHING;"
if [ $? -ne 0 ]; then
  echo "Lỗi khi thêm người dùng mặc định."
  exit 1
fi

echo "Đã khởi tạo cơ sở dữ liệu thành công!" 