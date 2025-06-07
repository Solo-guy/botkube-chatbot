// Import thư viện flutter_test để viết unit test cho Flutter
import 'package:flutter_test/flutter_test.dart';
// Import thư viện http để mô phỏng các yêu cầu HTTP
import 'package:http/http.dart' as http;
// Import mockito để tạo các đối tượng giả lập (mock)
import 'package:mockito/mockito.dart';
// Import file api_service.dart chứa lớp ApiService cần kiểm thử
import 'api_service.dart';
// Import testing từ package http để tạo MockClient
import 'package:http/testing.dart';

// Hàm main, điểm bắt đầu của các bài kiểm thử
void main() {
  // Nhóm các bài kiểm thử cho lớp ApiService
  group('ApiService', () {
    // Bài kiểm thử 1: Kiểm tra executeCommand trả về output khi gọi API thành công
    test('executeCommand returns output on success', () async {
      // Tạo MockClient giả lập phản hồi HTTP
      final mockClient = MockClient((request) async {
        // Mô phỏng phản hồi HTTP 200 với JSON {"output":"Executing command: get pods"}
        return http.Response('{"output":"Executing command: get pods"}', 200);
      });

      // Tạo instance của ApiService để kiểm thử
      final apiService = ApiService();
      // Gọi hàm executeCommand với lệnh "get pods"
      final result = await apiService.executeCommand('get pods');

      // Kiểm tra kết quả trả về đúng như mong đợi
      expect(result, 'Executing command: get pods');
    });

    // Bài kiểm thử 2: Kiểm tra executeCommand trả về lỗi khi gọi API thất bại
    test('executeCommand returns error on failure', () async {
      // Tạo MockClient giả lập phản hồi HTTP
      final mockClient = MockClient((request) async {
        // Mô phỏng phản hồi HTTP 404 với thông báo "Not Found"
        return http.Response('Not Found', 404);
      });

      // Tạo instance của ApiService để kiểm thử
      final apiService = ApiService();
      // Gọi hàm executeCommand với lệnh "get pods"
      final result = await apiService.executeCommand('get pods');

      // Kiểm tra kết quả trả về thông báo lỗi với mã trạng thái
      expect(result, 'Error: 404');
    });
  });
}
