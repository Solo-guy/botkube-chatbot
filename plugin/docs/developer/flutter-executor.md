# Flutter Executor Plugin (Developer Guide)

<!-- Tiêu đề chính của tài liệu, mô tả đây là hướng dẫn phát triển cho plugin flutter-executor -->

## Overview

<!-- Phần tổng quan, giới thiệu ngắn gọn về plugin -->

Plugin `flutter-executor` cung cấp REST API để ứng dụng Flutter gửi lệnh đến Botkube.

<!-- Mô tả chức năng chính: plugin cung cấp API REST cho phép ứng dụng Flutter gửi lệnh tới Botkube -->

## Development

<!-- Phần hướng dẫn phát triển, cung cấp thông tin kỹ thuật cho lập trình viên -->

- **Tech stack**: Go, Botkube SDK.
  <!-- Công nghệ sử dụng: ngôn ngữ Go và Botkube SDK để xây dựng plugin -->
- **API**: POST `/execute` nhận JSON `{ "command": "get pods" }`.
  <!-- Mô tả API: endpoint /execute nhận yêu cầu POST với body JSON chứa trường command -->
- **Build**: `go build -o flutter-executor`.
  <!-- Hướng dẫn biên dịch mã nguồn thành file thực thi tên flutter-executor -->
- **Test**: `go test`.
  <!-- Hướng dẫn chạy unit test để kiểm tra mã nguồn -->

## Setup

<!-- Phần hướng dẫn thiết lập và triển khai plugin -->

1. Build Docker: `docker build -t your-docker-username/flutter-executor:latest .`
   <!-- Bước 1: Build Docker image từ Dockerfile, tạo image với tên your-docker-username/flutter-executor:latest -->
2. Push: `docker push your-docker-username/flutter-executor:latest`
   <!-- Bước 2: Đẩy image lên Docker Hub để Botkube có thể kéo về sử dụng -->
3. Update Helm: `helm upgrade --install botkube botkube/botkube -n botkube -f values.yaml`
   <!-- Bước 3: Cập nhật hoặc cài đặt Botkube qua Helm, sử dụng file values.yaml chứa cấu hình plugin -->
