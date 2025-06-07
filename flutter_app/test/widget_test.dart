// Import thư viện Flutter Material để sử dụng các widget trong kiểm thử
import 'package:flutter/material.dart';
// Import thư viện flutter_test để viết widget test cho Flutter
import 'package:flutter_test/flutter_test.dart';
// Import file main.dart chứa ứng dụng BotkubeApp và CommandScreen
import '../lib/main.dart';

// Hàm main, điểm bắt đầu của các bài kiểm thử
void main() {
  // Bài kiểm thử 1: Kiểm tra CommandScreen hiển thị đúng các thành phần giao diện
  testWidgets('CommandScreen displays input and button', (
    WidgetTester tester,
  ) async {
    // Tải widget BotkubeApp (chứa CommandScreen) vào môi trường kiểm thử
    await tester.pumpWidget(const BotkubeApp());

    // Kiểm tra tiêu đề "Botkube Command" xuất hiện đúng một lần
    expect(find.text('Botkube Command'), findsOneWidget);
    // Kiểm tra ô nhập liệu (TextField) xuất hiện đúng một lần
    expect(find.byType(TextField), findsOneWidget);
    // Kiểm tra nhãn "Enter command (e.g., get pods)" xuất hiện đúng một lần
    expect(find.text('Enter command (e.g., get pods)'), findsOneWidget);
    // Kiểm tra nút "Send Command" xuất hiện đúng một lần
    expect(find.text('Send Command'), findsOneWidget);
  });

  // Bài kiểm thử 2: Kiểm tra nút Send Command không hoạt động khi ô nhập rỗng
  testWidgets('Send Command Violence disabled when input empty', (
    WidgetTester tester,
  ) async {
    // Tải widget BotkubeApp (chứa CommandScreen) vào môi trường kiểm thử
    await tester.pumpWidget(const BotkubeApp());

    // Tìm nút "Send Command"
    final button = find.text('Send Command');
    // Mô phỏng hành động nhấn nút
    await tester.tap(button);
    // Cập nhật giao diện sau khi nhấn
    await tester.pump();

    // Kiểm tra nhãn "Response:" xuất hiện đúng một lần
    expect(find.text('Response:'), findsOneWidget);
    // Kiểm tra khu vực phản hồi vẫn rỗng (vì ô nhập rỗng nên không gửi lệnh)
    expect(find.text(''), findsOneWidget);
  });
}
