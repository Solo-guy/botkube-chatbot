# Xử lý sự cố

Tài liệu này cung cấp hướng dẫn để giải quyết các vấn đề thường gặp khi sử dụng BotKube Flutter App.

## Vấn đề khởi động

### Không thể khởi động CockroachDB

**Triệu chứng**: Lỗi khi chạy lệnh `cockroach start-single-node`

**Giải pháp**:

1. Kiểm tra xem CockroachDB đã được cài đặt đúng cách
2. Kiểm tra port 26257 đã được sử dụng bởi ứng dụng khác chưa

   ```bash
   # Windows
   netstat -ano | findstr 26257

   # Linux/macOS
   lsof -i :26257
   ```

3. Nếu port đã được sử dụng, hãy chọn port khác và cập nhật trong các file cấu hình
4. Nếu CockroachDB đã chạy nhưng không thể kết nối, hãy thử khởi động lại:
   ```bash
   cockroach quit --insecure
   cockroach start-single-node --insecure
   ```

### Lỗi khi chạy Flutter Executor

**Triệu chứng**: Lỗi khi chạy `go run main.go` trong thư mục `plugin/flutter-executor`

**Giải pháp**:

1. Kiểm tra lỗi kết nối database. Nếu không thể kết nối tới CockroachDB:
   - Đảm bảo CockroachDB đang chạy
   - Kiểm tra cấu hình kết nối trong `config.yaml`
2. Kiểm tra xem port 8080 đã được sử dụng chưa

   ```bash
   # Windows
   netstat -ano | findstr 8080

   # Linux/macOS
   lsof -i :8080
   ```

3. Nếu cần, bạn có thể thay đổi port trong `config.yaml`
4. Kiểm tra xem các module Go đã được cài đặt đầy đủ:
   ```bash
   go mod tidy
   ```

### Lỗi khi chạy AI Manager

**Triệu chứng**: Lỗi khi chạy `go run main.go ai.go` trong thư mục `plugin/ai-manager`

**Giải pháp**:

1. Kiểm tra lỗi kết nối database
2. Kiểm tra xem JWT token trong `config.yaml` có đúng không
3. Kiểm tra xem các module Go đã được cài đặt đầy đủ:
   ```bash
   go mod tidy
   ```

### Lỗi khi chạy ứng dụng Flutter

**Triệu chứng**: Lỗi khi chạy `flutter run -d chrome`

**Giải pháp**:

1. Kiểm tra xem Flutter đã được cài đặt đúng cách
   ```bash
   flutter doctor
   ```
2. Kiểm tra xem các dependency đã được cài đặt
   ```bash
   flutter pub get
   ```
3. Nếu có lỗi về Chrome, hãy kiểm tra xem Chrome đã được cài đặt và cập nhật
4. Thử chạy trên thiết bị khác:
   ```bash
   flutter devices
   flutter run -d [device-id]
   ```

## Vấn đề xác thực

### Không thể đăng nhập

**Triệu chứng**: Thông báo lỗi khi đăng nhập

**Giải pháp**:

1. Kiểm tra xem bạn đang sử dụng đúng tài khoản (mặc định là `user1`)
2. Kiểm tra danh sách người dùng trong `plugin/flutter-executor/config.yaml`
3. Kiểm tra xem Flutter Executor có đang chạy không
4. Kiểm tra xem cấu hình API URL trong `.env` có đúng không

### Token JWT hết hạn

**Triệu chứng**: Thông báo "Token hết hạn" hoặc "Unauthorized"

**Giải pháp**:

1. Đăng xuất và đăng nhập lại
2. Xóa dữ liệu trình duyệt và cookie, sau đó thử lại
3. Nếu vẫn gặp lỗi, kiểm tra cấu hình JWT trong các file config

## Vấn đề kết nối

### Không thể kết nối tới API

**Triệu chứng**: Ứng dụng không thể tải dữ liệu

**Giải pháp**:

1. Kiểm tra xem Flutter Executor có đang chạy không
2. Kiểm tra file `.env` trong thư mục `flutter_app`, đảm bảo API_URL đúng
3. Kiểm tra xem có firewall hoặc proxy đang chặn kết nối không
4. Thử sửa API_URL thành địa chỉ IP thay vì localhost:
   ```
   API_URL=http://127.0.0.1:8080
   ```

### Lỗi CORS

**Triệu chứng**: Lỗi CORS trong console của trình duyệt

**Giải pháp**:

1. Đảm bảo service Flutter Executor đã được cấu hình để cho phép CORS
2. Nếu đang chạy trên localhost, hãy thử sử dụng extension CORS Unblock cho trình duyệt
3. Nếu triển khai trên server, cấu hình nginx hoặc apache để cho phép CORS

## Vấn đề hiệu suất

### Ứng dụng chạy chậm

**Triệu chứng**: Giao diện phản hồi chậm, tải dữ liệu lâu

**Giải pháp**:

1. Kiểm tra kết nối mạng
2. Nếu database lớn, cân nhắc tối ưu hóa truy vấn hoặc thêm index
3. Giảm số lượng sự kiện hiển thị trong một trang
4. Sử dụng chế độ hiển thị đơn giản hơn (nếu có)

### AI phản hồi chậm

**Triệu chứng**: Phân tích AI mất nhiều thời gian

**Giải pháp**:

1. Kiểm tra model AI đã chọn trong `plugin/ai-manager/config.yaml`
2. Nếu đang sử dụng API từ xa (OpenAI, Claude, v.v.), hãy kiểm tra kết nối
3. Cân nhắc sử dụng mô hình AI nhẹ hơn hoặc mô hình cục bộ

## Vấn đề khác

### Lỗi trong file nhật ký

**Làm thế nào để xem file nhật ký**:

- Flutter Executor và AI Manager ghi nhật ký vào stdout (terminal)
- Ứng dụng Flutter ghi nhật ký vào console của trình duyệt

**Giải pháp**:

1. Xem nhật ký để xác định lỗi chi tiết
2. Tìm kiếm thông báo lỗi cụ thể trong tài liệu hoặc forum

### Cần khởi động lại dịch vụ

Nếu gặp sự cố không thể giải quyết, thử khởi động lại toàn bộ hệ thống:

1. Dừng ứng dụng Flutter (Ctrl+C trong terminal)
2. Dừng AI Manager (Ctrl+C trong terminal)
3. Dừng Flutter Executor (Ctrl+C trong terminal)
4. Đảm bảo CockroachDB vẫn chạy
5. Khởi động lại các dịch vụ theo thứ tự đã mô tả trong [Hướng dẫn sử dụng](usage.md)

## Liên hệ hỗ trợ

Nếu bạn vẫn gặp vấn đề sau khi thử các giải pháp trên, vui lòng:

1. Kiểm tra các [issue đã biết](https://github.com/yourusername/botkube-flutter-clean/issues)
2. Tạo issue mới với mô tả chi tiết về vấn đề, bao gồm:
   - Bước tái hiện lỗi
   - Thông báo lỗi
   - Môi trường (hệ điều hành, phiên bản Flutter, Go, v.v.)
   - File nhật ký liên quan
