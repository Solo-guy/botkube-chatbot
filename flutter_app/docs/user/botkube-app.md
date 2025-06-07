# Botkube Flutter App (User Guide)

<!-- Tiêu đề chính của tài liệu, mô tả đây là hướng dẫn sử dụng cho người dùng ứng dụng Flutter tương tác với Botkube -->

## Overview

<!-- Phần tổng quan, giới thiệu ngắn gọn về chức năng ứng dụng -->

Ứng dụng này cho phép gửi lệnh Kubernetes qua giao diện Flutter.

<!-- Mô tả mục đích: ứng dụng cung cấp giao diện để người dùng gửi lệnh Kubernetes (như get pods) đến plugin flutter-executor -->

## Usage

<!-- Phần hướng dẫn sử dụng, giải thích cách dùng ứng dụng -->

- Nhập lệnh (e.g., `get pods`) và nhấn "Send Command".
  <!-- Hướng dẫn nhập lệnh vào ô TextField và nhấn nút Send Command để gửi -->
- Xem phản hồi trong phần "Response".
  <!-- Mô tả nơi hiển thị kết quả: khu vực Response trên giao diện, chứa output từ API -->

## Requirements

<!-- Phần yêu cầu hệ thống, liệt kê các điều kiện để sử dụng ứng dụng -->

- Plugin `flutter-executor` chạy trên Botkube.
  <!-- Yêu cầu plugin flutter-executor (từ main.go) được triển khai và chạy trong môi trường Botkube -->
