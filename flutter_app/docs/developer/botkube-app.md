# Botkube Flutter App (Developer Guide)

<!-- Tiêu đề chính của tài liệu, mô tả đây là hướng dẫn phát triển cho ứng dụng Flutter tương tác với Botkube -->

## Overview

<!-- Phần tổng quan, giới thiệu ngắn gọn về ứng dụng -->

Ứng dụng Flutter gửi lệnh đến plugin `flutter-executor` qua REST API.

<!-- Mô tả chức năng chính: ứng dụng Flutter gửi lệnh (như get pods) đến plugin flutter-executor thông qua API REST -->

## Development

<!-- Phần hướng dẫn phát triển, cung cấp thông tin kỹ thuật cho lập trình viên -->

- **Tech stack**: Flutter, Dart, HTTP package.
    <!-- Công nghệ sử dụng: Flutter và Dart để xây dựng giao diện, package http để gọi API -->
  ­ly
- **API**: POST `/execute` với JSON `{ "command": "get pods" }`.
  <!-- Mô tả API: endpoint /execute nhận yêu cầu POST với body JSON chứa trường command -->
- **Run**: `flutter run -d chrome`.
  <!-- Hướng dẫn chạy ứng dụng trên trình duyệt Chrome (web platform) -->
- **Test**: `flutter test`.
  <!-- Hướng dẫn chạy unit test và widget test để kiểm tra mã nguồn -->

## Setup

<!-- Phần hướng dẫn thiết lập và triển khai ứng dụng -->

1. Install dependencies: `flutter pub get`.
   <!-- Bước 1: Cài đặt các package được khai báo trong pubspec.yaml -->
2. Run: `flutter run`.
   <!-- Bước 2: Chạy ứng dụng trên thiết bị hoặc mô phỏng (tự động chọn nền tảng nếu không chỉ định) -->
3. Build web: `flutter build web`.
   <!-- Bước 3: Biên dịch ứng dụng thành phiên bản web, tạo thư mục build/web -->
