# Flutter Executor Plugin (User Guide)

<!-- Tiêu đề chính của tài liệu, mô tả đây là hướng dẫn sử dụng cho người dùng plugin flutter-executor -->

## Overview

<!-- Phần tổng quan, giới thiệu ngắn gọn về chức năng plugin -->

Plugin này cho phép gửi lệnh Kubernetes từ ứng dụng Flutter qua REST API.

<!-- Mô tả mục đích: plugin cho phép ứng dụng Flutter gửi lệnh Kubernetes (như get pods) thông qua API REST -->

## Usage

<!-- Phần hướng dẫn sử dụng, giải thích cách dùng plugin -->

- Gửi yêu cầu POST đến `/execute` với JSON `{ "command": "get pods" }`.
  <!-- Hướng dẫn gửi yêu cầu HTTP POST đến endpoint /execute với body JSON chứa trường command -->
- Phản hồi: JSON `{ "output": "Executing command: get pods" }`.
  <!-- Mô tả định dạng phản hồi: JSON với trường output chứa kết quả xử lý lệnh -->

## Requirements

<!-- Phần yêu cầu hệ thống, liệt kê các điều kiện để sử dụng plugin -->

- Botkube chạy trên K3s.
  <!-- Yêu cầu Botkube được triển khai trên K3s, một bản phân phối Kubernetes nhẹ -->
- Plugin được cài qua Helm.
  <!-- Yêu cầu plugin được cài đặt và cấu hình thông qua Helm, công cụ quản lý ứng dụng Kubernetes -->
