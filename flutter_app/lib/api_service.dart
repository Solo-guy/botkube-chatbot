import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' show min;
import 'dart:async';
import 'utils/config.dart';
import '../models/event.dart';
import '../models/history.dart';
import '../models/workflow.dart';
import 'dart:math' as math;

class ApiService {
  static String baseUrl = AppConfig.apiUrl;
  static String wsUrl = AppConfig.wsUrl;
  int retryCount = 0;

  // Hàm helper để decode JSON với UTF-8
  dynamic _decodeUtf8Json(http.Response response) {
    final String utf8Body = utf8.decode(response.bodyBytes);
    return json.decode(utf8Body);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? "";
  }

  Future<String> login(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        final data = _decodeUtf8Json(response);
        // Lưu token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        // Lưu username
        await prefs.setString('username', username);

        // Tự động gán vai trò dựa trên username
        // user1 là admin, user2 và các user khác là user thông thường
        String role = username == 'user1' ? 'admin' : 'user';
        await prefs.setString('user_role', role);

        return data['token'];
      } else {
        throw Exception('Đăng nhập thất bại: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  Future<String> sendCommand(String command, String token) async {
    try {
      // Kiểm tra token trước
      if (token.isEmpty) {
        print('Error: Token rỗng trong sendCommand');
        return 'Lỗi: Chưa đăng nhập. Vui lòng đăng nhập trước.';
      }

      // Kiểm tra vai trò người dùng trước khi gửi lệnh
      final prefs = await SharedPreferences.getInstance();
      String? role = prefs.getString('user_role');

      print('Gửi lệnh với token (${token.length} ký tự) và vai trò: $role');

      // Nếu đã đăng nhập nhưng không phải admin
      if (role != 'admin') {
        print('Từ chối quyền: Người dùng không phải admin (vai trò: $role)');
        return 'Bạn không đủ quyền hạn để thực hiện lệnh này. Chỉ admin mới có thể tương tác với Botkube.';
      }

      // Thực hiện API call
      print('Gọi API /execute với lệnh: $command');
      final response = await http.post(
        Uri.parse('$baseUrl/execute'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'command': command}),
      );

      print('Nhận phản hồi từ API: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = _decodeUtf8Json(response);
        return data['output'];
      } else if (response.statusCode == 401) {
        return 'Lỗi: Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      } else {
        return 'Lỗi: ${response.statusCode}';
      }
    } catch (e) {
      print('Lỗi ngoại lệ trong sendCommand: $e');
      return 'Lỗi: $e';
    }
  }

  Future<Map<String, dynamic>> analyzeEvent(Event event, String token,
      {String model = 'azure'}) async {
    return _processRequest(
        'analyze-event',
        {
          'event': event.toJson(),
        },
        token,
        model: model);
  }

  Future<List<HistoryEntry>> getHistory(String token, {int? timestamp}) async {
    try {
      // Tạo URI có thêm tham số timestamp để tránh cache nếu được cung cấp
      var uri = Uri.parse('$baseUrl/history');
      if (timestamp != null) {
        uri = uri.replace(queryParameters: {'_t': timestamp.toString()});
      }

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        final data = _decodeUtf8Json(response) as List;
        print('History data received:');
        for (var item in data) {
          print(
              'History entry ID: ${item['id']}, UserID: ${item['user_id']}, Timestamp: ${item['timestamp']}');
        }
        return data.map((e) => HistoryEntry.fromJson(e)).toList();
      } else {
        throw Exception(
            'Lấy lịch sử chat thất bại: ${response.statusCode}. Vui lòng kiểm tra lại kết nối hoặc token xác thực.');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy lịch sử chat: $e. Vui lòng thử lại sau.');
    }
  }

  Future<List<dynamic>> fetchHistory() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return []; // Trả về danh sách rỗng thay vì ném ngoại lệ
    }

    try {
      // Add timestamp to prevent caching
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.parse('$baseUrl/history')
          .replace(queryParameters: {'_t': currentTimestamp.toString()});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        return _decodeUtf8Json(response);
      } else if (response.statusCode == 401) {
        print('Phiên đăng nhập hết hạn. Cần đăng nhập lại.');
        return [];
      } else {
        print('Lỗi khi tải lịch sử: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Lỗi khi tải lịch sử: $e');
      return [];
    }
  }

  Future<void> sendChatMessage(String message, String response) async {
    final token = await _getToken();
    final username = await SharedPreferences.getInstance()
        .then((prefs) => prefs.getString('username') ?? 'user1');
    await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': username,
        'message': message,
        'response': response,
      }),
    );
  }

  WebSocketChannel connectToWebSocket() {
    // Note: web_socket_channel currently does not support headers in connect method directly.
    // Token will need to be handled in a custom way if required by the server.
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    // Listen for connection errors or closure
    channel.stream.listen(
      (data) {
        // Handle incoming data
        print('WebSocket data received: $data');
      },
      onError: (error) {
        print('WebSocket error: $error');
        // Here you can add logic to notify the user or attempt reconnection
        _attemptReconnect();
      },
      onDone: () {
        print('WebSocket connection closed');
        // Here you can add logic to notify the user or attempt reconnection
        _attemptReconnect();
      },
    );
    return channel;
  }

  void _attemptReconnect() {
    const int maxRetries = 5;
    if (retryCount < maxRetries) {
      print(
          'Attempting to reconnect to WebSocket... (Attempt ${retryCount + 1}/$maxRetries)');
      Future.delayed(Duration(seconds: 10), () {
        print('Reconnecting...');
        retryCount++;
        connectToWebSocket();
      });
    } else {
      print(
          'Max reconnection attempts reached. Please check your network or server status.');
      retryCount = 0; // Reset for future attempts
    }
  }

  // Xóa một mục lịch sử dựa trên mã định danh
  Future<Map<String, dynamic>> deleteHistoryEntry(
      String messageId, String token) async {
    try {
      print('Đang xóa lịch sử với ID: $messageId');
      if (messageId.isEmpty) {
        print('Lỗi: ID lịch sử rỗng, không thể thực hiện xóa');
        return {
          'success': false,
          'message': 'ID lịch sử rỗng, không thể thực hiện xóa'
        };
      }

      // Tạo URL với ID gốc
      final url = Uri.parse('$baseUrl/history/$messageId');
      print('Gửi request DELETE đến: $url');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(Duration(milliseconds: AppConfig.apiTimeout));

      print(
          'Kết quả xóa lịch sử: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Xóa lịch sử thành công: ${response.body}');
        return {
          'success': true,
          'message': 'Đã xóa lịch sử thành công',
        };
      } else {
        String errorMessage = 'Lỗi khi xóa lịch sử: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Không thể parse JSON, sử dụng message mặc định
          errorMessage =
              'Lỗi khi xóa lịch sử: ${response.statusCode} - ${response.body}';
        }

        print('Lỗi khi xóa lịch sử: ${response.statusCode} - $errorMessage');

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('Chi tiết lỗi: $e');
      return {'success': false, 'message': 'Đã xảy ra lỗi khi xóa lịch sử: $e'};
    }
  }

  // Xóa toàn bộ lịch sử chat
  Future<Map<String, dynamic>> deleteAllHistory(String token) async {
    try {
      print('Đang yêu cầu xóa toàn bộ lịch sử');

      // Thay đổi từ DELETE /history sang POST /history/delete-all
      final url = Uri.parse('$baseUrl/history/delete-all');
      print('Gửi request POST đến: $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            // Gửi một body rỗng vì chúng ta chỉ cần xác thực token
            body: jsonEncode({}),
          )
          .timeout(Duration(milliseconds: AppConfig.apiTimeout));

      print(
          'Kết quả xóa toàn bộ lịch sử: ${response.statusCode}, Body: ${response.body}');

      // Nếu server trả về 200 OK hoặc 204 No Content
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Xóa toàn bộ lịch sử thành công');
        return {
          'success': true,
          'message': 'Đã xóa toàn bộ lịch sử thành công',
        };
      } else {
        String errorMessage =
            'Lỗi khi xóa toàn bộ lịch sử: ${response.statusCode}';
        try {
          if (response.body.isNotEmpty) {
            final errorData = json.decode(response.body);
            if (errorData is Map<String, dynamic> &&
                errorData.containsKey('message')) {
              errorMessage = errorData['message'];
            }
          }
        } catch (e) {
          errorMessage =
              'Lỗi khi xóa toàn bộ lịch sử: ${response.statusCode} - ${response.body}';
        }

        print(
            'Lỗi khi xóa toàn bộ lịch sử: ${response.statusCode} - $errorMessage');

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('Chi tiết lỗi khi xóa toàn bộ lịch sử: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi khi xóa toàn bộ lịch sử: $e'
      };
    }
  }

  // Process Kubernetes command with the AI server
  Future<Map<String, dynamic>> processKubernetesEvent(
      String prompt, String token,
      {String model = 'grok', bool saveToHistory = false}) async {
    try {
      // Use the existing _processRequest method
      final response = await _processRequest(
          'process-kubernetes', {'prompt': prompt}, token,
          model: model, saveToHistory: saveToHistory);

      // Check for echo responses where AI just repeats the user's command
      if (response['response'] != null &&
          _isEchoResponse(prompt, response['response'].toString())) {
        print(
            'Echo response detected in Kubernetes command, replacing with informative message');
        response['response'] = _generateKubernetesInformativeResponse(prompt);

        // Add corresponding workflow
        if (!response.containsKey('workflow') || response['workflow'] == null) {
          response['workflow'] = [
            "Kiểm tra danh sách pod với lệnh: kubectl get pods",
            "Xem chi tiết pod với lệnh: kubectl describe pod <tên-pod>",
            "Xem logs của pod với lệnh: kubectl logs <tên-pod>"
          ];
        }
      }

      return response;
    } catch (e) {
      // Check if it's a connectivity issue
      if (_isNetworkError(e)) {
        return _createOfflineResponse(prompt, true);
      }

      throw e;
    }
  }

  // Generate informative Kubernetes-specific response when server returns an echo
  String _generateKubernetesInformativeResponse(String command) {
    final lowerCommand = command.toLowerCase();

    // For pod-related commands
    if (lowerCommand.contains('pod') || lowerCommand.contains('pods')) {
      return "Để kiểm tra pods trong Kubernetes, bạn có thể sử dụng các lệnh sau:\n\n"
          "1. Liệt kê tất cả pods: `kubectl get pods`\n"
          "2. Lọc pods theo labels: `kubectl get pods -l app=my-app`\n"
          "3. Xem chi tiết pod: `kubectl describe pod <tên-pod>`\n"
          "4. Xem logs: `kubectl logs <tên-pod>`\n"
          "5. Xem tình trạng lịch sử của pod: `kubectl get events --field-selector involvedObject.name=<tên-pod>`";
    }

    // For node-related commands
    if (lowerCommand.contains('node') || lowerCommand.contains('nodes')) {
      return "Để kiểm tra nodes trong Kubernetes, bạn có thể sử dụng các lệnh sau:\n\n"
          "1. Liệt kê tất cả nodes: `kubectl get nodes`\n"
          "2. Xem chi tiết node: `kubectl describe node <tên-node>`\n"
          "3. Xem tài nguyên của node: `kubectl top node`\n"
          "4. Xem pods đang chạy trên node: `kubectl get pods --field-selector spec.nodeName=<tên-node> -A`";
    }

    // For deployment-related commands
    if (lowerCommand.contains('deploy') ||
        lowerCommand.contains('deployment')) {
      return "Để làm việc với deployments trong Kubernetes, bạn có thể sử dụng các lệnh sau:\n\n"
          "1. Liệt kê tất cả deployments: `kubectl get deployments`\n"
          "2. Xem chi tiết deployment: `kubectl describe deployment <tên-deployment>`\n"
          "3. Xem lịch sử rollout: `kubectl rollout history deployment/<tên-deployment>`\n"
          "4. Scale deployment: `kubectl scale deployment/<tên-deployment> --replicas=3`";
    }

    // For service-related commands
    if (lowerCommand.contains('service') || lowerCommand.contains('svc')) {
      return "Để làm việc với services trong Kubernetes, bạn có thể sử dụng các lệnh sau:\n\n"
          "1. Liệt kê tất cả services: `kubectl get services`\n"
          "2. Xem chi tiết service: `kubectl describe service <tên-service>`\n"
          "3. Expose deployment dưới dạng service: `kubectl expose deployment <tên-deployment> --port=8080 --target-port=80`";
    }

    // General Kubernetes command
    return "Để thực hiện lệnh Kubernetes, bạn có thể sử dụng kubectl. Một số lệnh phổ biến:\n\n"
        "1. Liệt kê tài nguyên: `kubectl get <resource-type>`\n"
        "2. Xem chi tiết tài nguyên: `kubectl describe <resource-type> <name>`\n"
        "3. Xem logs: `kubectl logs <pod-name>`\n"
        "4. Thực thi lệnh trong container: `kubectl exec -it <pod-name> -- <command>`\n"
        "5. Áp dụng cấu hình: `kubectl apply -f <filename.yaml>`";
  }

  // Process natural language query with a model
  Future<Map<String, dynamic>> processNaturalLanguage(
      String message, String token,
      {String model = 'grok', bool saveToHistory = false}) async {
    try {
      // Use the existing _processRequest method
      final response = await _processRequest(
          'query', {'prompt': message}, token,
          model: model, saveToHistory: saveToHistory);

      // Check for echo responses where AI just repeats the user's question
      if (response['response'] != null &&
          _isEchoResponse(message, response['response'].toString())) {
        print('Echo response detected, replacing with informative message');
        response['response'] = _generateInformativeResponse(message);

        // Add corresponding workflow
        if (!response.containsKey('workflow') || response['workflow'] == null) {
          response['workflow'] = _generateContextualWorkflow(message);
        }
      }

      return response;
    } catch (e) {
      // Check if it's a connectivity issue
      if (_isNetworkError(e)) {
        return _createOfflineResponse(message, false);
      }

      throw e;
    }
  }

  // Generate informative response when server returns an echo
  String _generateInformativeResponse(String message) {
    final lowerMessage = message.toLowerCase();

    // Check for Kubernetes-related queries
    if (_isKubernetesCommand(message)) {
      return "Để kiểm tra thông tin về pod trong Kubernetes, bạn có thể sử dụng các lệnh sau:\n\n"
          "1. Liệt kê tất cả pods: `kubectl get pods`\n"
          "2. Xem chi tiết về một pod: `kubectl describe pod <tên-pod>`\n"
          "3. Xem logs của pod: `kubectl logs <tên-pod>`\n\n"
          "Lưu ý: Đảm bảo rằng bạn đã cấu hình đúng context Kubernetes và có quyền truy cập đến namespace chứa pod.";
    }

    // Check for common ghost/supernatural queries ("ma" in Vietnamese)
    if (lowerMessage.contains('ma') ||
        lowerMessage.contains('quỷ') ||
        lowerMessage.contains('tâm linh')) {
      return "Về chủ đề liên quan đến ma quỷ hoặc tâm linh, có nhiều quan điểm văn hóa và tín ngưỡng khác nhau. Một số người tin vào sự tồn tại của thế giới tâm linh, trong khi những người khác coi đó là hiện tượng tâm lý hoặc văn hóa. Nếu bạn quan tâm đến chủ đề này, tôi khuyên bạn nên tìm hiểu từ nhiều nguồn đáng tin cậy và tham khảo ý kiến từ các chuyên gia về tâm lý hoặc văn hóa.";
    }

    // General fallback response
    return "Tôi đang gặp khó khăn trong việc xử lý yêu cầu của bạn. Điều này có thể do kết nối mạng không ổn định hoặc máy chủ đang bận. Vui lòng thử lại sau một lát hoặc đặt câu hỏi theo cách khác.";
  }

  // Create a contextual workflow based on message content
  List<String> _generateContextualWorkflow(String message) {
    final lowerMessage = message.toLowerCase();

    // Check for Kubernetes-related queries
    if (_isKubernetesCommand(message)) {
      return [
        "Kiểm tra danh sách pod với lệnh: kubectl get pods",
        "Xem chi tiết pod với lệnh: kubectl describe pod <tên-pod>",
        "Xem logs của pod với lệnh: kubectl logs <tên-pod>"
      ];
    }

    // Check for common ghost/supernatural queries ("ma" in Vietnamese)
    if (lowerMessage.contains('ma') ||
        lowerMessage.contains('quỷ') ||
        lowerMessage.contains('tâm linh')) {
      return [
        "Tìm hiểu các tài liệu về tâm linh hoặc triết học.",
        "Tham khảo ý kiến từ chuyên gia về tâm lý hoặc tâm linh.",
        "Khám phá các phương pháp thiền định để cải thiện sức khỏe tinh thần."
      ];
    }

    // Default general-purpose workflow
    return [
      "Tìm kiếm thêm thông tin về chủ đề này.",
      "Tham khảo ý kiến của chuyên gia nếu cần thiết.",
      "Ghi chú lại thông tin hữu ích để tham khảo sau."
    ];
  }

  // Helper to identify network errors
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup');
  }

  // Create response for offline mode
  Map<String, dynamic> _createOfflineResponse(
      String message, bool isKubernetes) {
    String response;
    List<String> workflow;

    if (isKubernetes) {
      response = _getKubernetesFallbackResponse(message);
      workflow = [
        "Kiểm tra danh sách pod với lệnh: kubectl get pods",
        "Xem chi tiết pod với lệnh: kubectl describe pod <tên-pod>",
        "Xem logs của pod với lệnh: kubectl logs <tên-pod>"
      ];
    } else if (_isGhostRelatedQuery(message)) {
      response =
          "Về chủ đề liên quan đến ma quỷ hoặc tâm linh, có nhiều quan điểm văn hóa và tín ngưỡng khác nhau. Một số người tin vào sự tồn tại của thế giới tâm linh, trong khi những người khác coi đó là hiện tượng tâm lý hoặc văn hóa. Nếu bạn quan tâm đến chủ đề này, tôi khuyên bạn nên tìm hiểu từ nhiều nguồn đáng tin cậy và tham khảo ý kiến từ các chuyên gia về tâm lý hoặc văn hóa.";
      workflow = [
        "Tìm hiểu các tài liệu về tâm linh hoặc triết học.",
        "Tham khảo ý kiến từ chuyên gia về tâm lý hoặc tâm linh.",
        "Khám phá các phương pháp thiền định để cải thiện sức khỏe tinh thần."
      ];
    } else {
      response =
          "Tôi đang làm việc ở chế độ ngoại tuyến. Không thể xử lý yêu cầu của bạn. " +
              "Vui lòng kiểm tra kết nối mạng và thử lại sau.";
      workflow = [
        "Kiểm tra kết nối mạng của bạn.",
        "Đảm bảo máy chủ đang hoạt động.",
        "Thử lại sau khi kết nối đã ổn định."
      ];
    }

    return {
      'success': true,
      'is_fallback': true,
      'response': response,
      'analysis': response,
      'workflow': workflow
    };
  }

  // Refresh the authentication token
  Future<String?> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? 'user1';
      final password = prefs.getString('password') ?? '';
      if (username.isEmpty || password.isEmpty) {
        return null;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final newToken = responseData['token'] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          await prefs.setString('auth_token', newToken);
          return newToken;
        }
      }
      return null;
    } catch (e) {
      print('Error refreshing token: $e');
      return null;
    }
  }

  // Public method to check server connectivity that can be called from widgets
  Future<bool> checkServerConnection() async {
    try {
      final isConnected = await _checkServerConnection();
      return isConnected;
    } catch (e) {
      print('Error checking server connection: $e');
      return false;
    }
  }

  // Improved helper method to check server connectivity with multiple endpoints
  Future<bool> _checkServerConnection() async {
    try {
      // Try multiple endpoints to determine server availability
      final healthEndpoint = Uri.parse('${AppConfig.apiUrl}/health');
      final chatEndpoint = Uri.parse('${AppConfig.apiUrl}/chat');

      // Less intrusive approach - don't log too much
      // First try the health endpoint with a short timeout
      try {
        final healthResponse =
            await http.get(healthEndpoint).timeout(Duration(seconds: 2));

        if (healthResponse.statusCode == 200) {
          return true;
        }
      } catch (_) {
        // Silently continue to try other endpoints without logging
      }

      // If health endpoint fails, try the chat endpoint
      try {
        final chatResponse =
            await http.get(chatEndpoint).timeout(Duration(seconds: 2));

        // Even if we get an error code like 404 or 405, it means the server is up
        if (chatResponse.statusCode < 500) {
          return true;
        }
      } catch (_) {
        // Silently continue
      }

      // All checks failed
      return false;
    } catch (_) {
      // Silently catch any other errors
      return false;
    }
  }

  // Modified method with improved connectivity check
  Future<Map<String, dynamic>> _processRequest(
      String endpoint, Map<String, dynamic> data, String token,
      {String model = 'azure', bool saveToHistory = false}) async {
    // Don't do a server connection check before making the request
    // Let the actual request determine if the server is available

    // Use the model-specific timeout from AppConfig
    final timeout = AppConfig.getAiModelTimeout(model);

    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json; charset=utf-8',
    };

    // Log platform information for debugging
    print(
        'Processing request on platform: ${AppConfig.isWeb ? 'web' : 'native'}');
    print(
        'Device detected as: ${AppConfig.isMobileDevice ? 'mobile' : 'desktop/web'}');
    print('Using model: $model with timeout: ${timeout.inSeconds} seconds');

    // Normalize endpoints to match backend structure
    // Always use 'chat' endpoint for queries regardless of platform
    String formattedEndpoint;
    if (endpoint == 'query' || endpoint == 'process-kubernetes') {
      formattedEndpoint = 'chat';
      print('Normalizing endpoint from $endpoint to chat');
    } else if (endpoint == 'analyze-event') {
      formattedEndpoint = 'ai/analyze';
    } else {
      formattedEndpoint = endpoint;
    }

    // Tạo URL đầy đủ
    final url = Uri.parse('$baseUrl/$formattedEndpoint');

    print('Sending request to: $url with model: $model');

    try {
      // Ensure message field is present - it's what the backend expects
      if (data.containsKey('prompt')) {
        // Preserve Vietnamese characters in the prompt
        String prompt = data['prompt'].toString();

        // Log the Vietnamese characters for debugging
        if (prompt.contains(RegExp(
            r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]'))) {
          print('Request contains Vietnamese text: "$prompt"');
        }

        // Ensure we copy the prompt to message and maintain UTF-8 encoding
        data['message'] = prompt;
      }

      // Always include these fields
      data['model'] = model;
      data['saveToHistory'] = saveToHistory;

      // Convert the request body to JSON with UTF-8 encoding to preserve Vietnamese characters
      final String jsonBody = json.encode(data);
      print('Request payload (UTF-8): $jsonBody');

      // Thực hiện request với timeout phù hợp với nền tảng
      // Use utf8.encode to ensure Vietnamese characters are properly encoded
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonBody,
            encoding: Encoding.getByName('utf-8'), // Ensure UTF-8 encoding
          )
          .timeout(timeout);

      print('Response status code: ${response.statusCode}');

      // Properly decode the response with UTF-8 encoding
      String responseBody = utf8.decode(response.bodyBytes);

      // Log the response body for debugging
      print('Response body: $responseBody');

      if (response.statusCode == 200) {
        try {
          // Enhanced error handling for JSON parsing with UTF-8 support
          var jsonResponse = json.decode(responseBody);
          print('Successfully parsed JSON response: ${jsonResponse.keys}');

          // Add success flag if it doesn't exist
          if (!jsonResponse.containsKey('success')) {
            jsonResponse['success'] = true;
          }

          // Ensure response field exists and is valid
          if (!jsonResponse.containsKey('response') ||
              jsonResponse['response'] == null) {
            print('Response field missing or null, checking other fields');

            // Try extracting response from other possible field names
            if (jsonResponse.containsKey('content')) {
              print('Found content field, using as response');
              jsonResponse['response'] = jsonResponse['content'];
            } else if (jsonResponse.containsKey('analysis')) {
              print('Found analysis field, using as response');
              jsonResponse['response'] = jsonResponse['analysis'];
            } else if (jsonResponse.containsKey('message')) {
              print('Found message field, using as response');
              jsonResponse['response'] = jsonResponse['message'];
            } else {
              print('No valid response field found, using default message');
              jsonResponse['response'] = 'Không nhận được phản hồi từ máy chủ';
            }
          }

          // Ensure workflow field exists and is valid
          if (!jsonResponse.containsKey('workflow') ||
              jsonResponse['workflow'] == null) {
            print('Workflow field missing or null, adding empty array');
            jsonResponse['workflow'] = [];
          } else if (jsonResponse['workflow'] is! List) {
            print('Workflow is not a list, converting to proper list format');
            try {
              // Try to parse workflow as a string if it's not already a list
              if (jsonResponse['workflow'] is String) {
                String workflowStr = jsonResponse['workflow'] as String;
                // Try to parse as JSON array if it looks like one
                if (workflowStr.trim().startsWith('[') &&
                    workflowStr.trim().endsWith(']')) {
                  jsonResponse['workflow'] = json.decode(workflowStr);
                } else {
                  // Otherwise split by newlines or commas
                  jsonResponse['workflow'] = workflowStr
                      .split(RegExp(r'[\n,]'))
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                }
              } else {
                // If it's some other type, convert to empty array
                jsonResponse['workflow'] = [];
              }
            } catch (e) {
              print('Error parsing workflow: $e');
              jsonResponse['workflow'] = [];
            }
          }

          return jsonResponse;
        } catch (e) {
          print('Error parsing JSON response: $e');
          // If JSON parsing fails, create a valid fallback response
          return {
            'success': true,
            'response':
                'Đã nhận được phản hồi từ máy chủ nhưng không thể xử lý định dạng. Phản hồi gốc: ${responseBody.substring(0, min(100, responseBody.length))}...',
            'workflow': [],
            'error': 'JSON parsing error: $e'
          };
        }
      } else {
        // Handle error responses
        String errorMsg = 'Lỗi ${response.statusCode}';
        try {
          var errorJson = json.decode(responseBody);
          if (errorJson.containsKey('error')) {
            errorMsg = errorJson['error'].toString();
          } else if (errorJson.containsKey('message')) {
            errorMsg = errorJson['message'].toString();
          }
        } catch (e) {
          errorMsg = 'Lỗi ${response.statusCode}: $responseBody';
        }

        return {'success': false, 'error': errorMsg, 'response': null};
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Timeout: Request took too long to complete',
        'response': null
      };
    } catch (e) {
      return {'success': false, 'error': 'Error: $e', 'response': null};
    }
  }

  // New methods for workflow functionality
  Future<List<Workflow>> getWorkflows(String token) async {
    if (token.isEmpty) {
      return [];
    }

    try {
      // Lấy URL từ cấu hình
      final String apiUrl = '${AppConfig.apiUrl}/workflows';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse =
            jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse.map((json) => Workflow.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Lỗi khi lấy danh sách quy trình: $e');
      return [];
    }
  }

  Future<Workflow?> saveWorkflow(Workflow workflow, String token) async {
    int retryAttempts = 0;
    const maxRetries = 3;

    while (retryAttempts <= maxRetries) {
      try {
        if (token.isEmpty) {
          print('Error: Token rỗng trong saveWorkflow');
          return null;
        }

        print('Saving workflow to ${AppConfig.apiUrl}/workflows');
        final workflowData = workflow.toJson();
        print('Workflow data: ${json.encode(workflowData)}');

        final response = await http
            .post(
              Uri.parse('${AppConfig.apiUrl}/workflows'),
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(workflow.toJson()),
            )
            .timeout(Duration(seconds: 30));

        print('Save workflow response: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = _decodeUtf8Json(response);
          return Workflow.fromJson(data);
        } else if ((response.statusCode == 408 || response.statusCode == 504) &&
            retryAttempts < maxRetries) {
          // Timeout errors - retry
          retryAttempts++;
          final backoffDuration = Duration(seconds: 2 * (1 << retryAttempts));
          print(
              'Save workflow timed out. Retrying after ${backoffDuration.inSeconds}s...');
          await Future.delayed(backoffDuration);
          continue;
        } else {
          print('Lỗi khi lưu quy trình làm việc: ${response.statusCode}');
          print('Response body: ${response.body}');
          return null;
        }
      } on TimeoutException {
        if (retryAttempts < maxRetries) {
          retryAttempts++;
          final backoffDuration = Duration(seconds: 2 * (1 << retryAttempts));
          print(
              'Save workflow timed out. Retrying after ${backoffDuration.inSeconds}s...');
          await Future.delayed(backoffDuration);
          continue;
        }
        print(
            'Lỗi timeout khi lưu quy trình làm việc sau ${retryAttempts + 1} lần thử');
        return null;
      } catch (e) {
        if (retryAttempts < maxRetries &&
            (e.toString().contains('socket') ||
                e.toString().contains('connection'))) {
          retryAttempts++;
          final backoffDuration = Duration(seconds: 2 * (1 << retryAttempts));
          print(
              'Network error in saveWorkflow: $e. Retrying after ${backoffDuration.inSeconds}s...');
          await Future.delayed(backoffDuration);
          continue;
        }
        print('Lỗi ngoại lệ trong saveWorkflow: $e');
        return null;
      }
    }

    print('Failed to save workflow after ${maxRetries + 1} attempts');
    return null;
  }

  Future<bool> deleteWorkflow(String workflowId, String token) async {
    if (token.isEmpty) {
      return false;
    }

    try {
      // Lấy URL từ cấu hình
      final String apiUrl = '${AppConfig.apiUrl}/workflows/$workflowId';

      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi khi xóa quy trình: $e');
      return false;
    }
  }

  Future<List<Map<String, String>>> executeWorkflow(
      String workflowId, String token) async {
    if (token.isEmpty) {
      return [];
    }

    try {
      // Lấy URL từ cấu hình
      final String apiUrl = '${AppConfig.apiUrl}/workflows/$workflowId/execute';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 120));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse =
            jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse
            .map((json) => {
                  'output': (json['output'] ?? "").toString(),
                  'error': (json['error'] ?? "").toString(),
                })
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Lỗi khi thực thi quy trình: $e');
      return [];
    }
  }

  // Generate appropriate fallbacks for common queries
  String _generateLocalResponse(String query) {
    query = query.toLowerCase();

    // Generate appropriate fallbacks for common queries
    if (query.contains('pod') ||
        query.contains('kubectl') ||
        query.contains('kubernetes') ||
        query.contains('k8s')) {
      return "Để kiểm tra pod trong Kubernetes, bạn có thể sử dụng các lệnh sau:\n\n"
          "1. `kubectl get pods` - Liệt kê tất cả pods\n"
          "2. `kubectl describe pod <tên-pod>` - Xem thông tin chi tiết về pod\n"
          "3. `kubectl logs <tên-pod>` - Xem logs của pod\n\n"
          "Hiện tôi không thể kết nối với máy chủ Kubernetes, nhưng những lệnh trên sẽ giúp bạn bắt đầu.";
    } else if (query.contains('ma') ||
        query.contains('quỷ') ||
        query.contains('tâm linh') ||
        query.contains('chuyện ma')) {
      return "Tôi nhận thấy bạn đang hỏi về chủ đề liên quan đến tâm linh hoặc ma quỷ. "
          "Đây là chủ đề nhạy cảm và quan điểm có thể khác nhau tùy thuộc vào văn hóa và niềm tin cá nhân. "
          "Bạn có thể tìm hiểu thêm từ sách, phim ảnh hoặc các nguồn văn hóa dân gian đáng tin cậy.";
    } else {
      return "Tôi không thể kết nối với máy chủ AI để xử lý yêu cầu của bạn. "
          "Vui lòng thử lại sau hoặc kiểm tra kết nối mạng.";
    }
  }

  // Gửi message và nhận response
  Future<String> sendMessage(String message, String token,
      {String model = 'grok'}) async {
    if (token.isEmpty) {
      return "Vui lòng đăng nhập để tiếp tục.";
    }

    // Create a Completer to handle both timeout and success cases
    final responseCompleter = Completer<String>();
    String timeoutResponse = "";
    bool hasTimedOut = false;

    try {
      // Lấy URL từ cấu hình
      final String apiUrl = '${AppConfig.apiUrl}/message';

      // Get model-specific timeout
      final timeout = AppConfig.getAiModelTimeout(model);
      print('Using model $model with timeout: ${timeout.inSeconds}s');

      // Tạo request body
      final Map<String, dynamic> requestBody = {
        'message': message,
        'model': model,
      };

      print('Sending request to: $apiUrl');

      // Start a timeout timer that will complete with a fallback response
      Future.delayed(timeout).then((_) {
        if (!responseCompleter.isCompleted) {
          print('Request timed out after ${timeout.inSeconds}s');
          hasTimedOut = true;

          // Generate a timeout-specific response
          final lowerMessage = message.toLowerCase();
          if (lowerMessage.contains('pod') ||
              lowerMessage.contains('kubectl') ||
              lowerMessage.contains('kubernetes') ||
              lowerMessage.contains('k8s')) {
            timeoutResponse =
                "Yêu cầu của bạn về Kubernetes đã hết thời gian chờ. Đây có thể là do API của máy chủ đang tắt hoặc quá tải. Tôi có thể giúp bạn với một số thông tin cơ bản về Kubernetes, hoặc bạn có thể thử lại sau.";
          } else if (_isGhostRelatedQuery(message)) {
            timeoutResponse =
                "Yêu cầu của bạn liên quan đến chủ đề tâm linh hoặc ma quỷ đã hết thời gian chờ. Đây có thể là do việc tạo nội dung dài cần nhiều thời gian hơn. Bạn có thể thử lại với yêu cầu ngắn gọn hơn.";
          } else {
            timeoutResponse =
                "Quá thời gian chờ phản hồi. Máy chủ AI có thể đang bận. Vui lòng thử lại sau hoặc với câu hỏi ngắn gọn hơn.";
          }

          // Complete with timeout response
          responseCompleter.complete(timeoutResponse);

          // Save timeout response to history
          sendChatMessage(message, timeoutResponse);
        }
      });

      // Fire the actual HTTP request without awaiting it
      http
          .post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      )
          .then((response) {
        // Process successful response
        print('Response status code: ${response.statusCode}');
        final String responseBody = utf8.decode(response.bodyBytes);
        print('Response body: $responseBody');

        if (response.statusCode == 200) {
          try {
            final jsonResponse = jsonDecode(responseBody);
            String aiResponse = "Không có phản hồi";

            // Try to extract response from different possible fields
            if (jsonResponse.containsKey('response') &&
                jsonResponse['response'] != null) {
              aiResponse = jsonResponse['response'].toString();
            } else if (jsonResponse.containsKey('content') &&
                jsonResponse['content'] != null) {
              aiResponse = jsonResponse['content'].toString();
            } else if (jsonResponse.containsKey('message') &&
                jsonResponse['message'] != null) {
              aiResponse = jsonResponse['message'].toString();
            }

            // Check if the response is just echoing back the query
            if (aiResponse.startsWith("Phân tích sự kiện: ")) {
              String echoedQuery =
                  aiResponse.substring("Phân tích sự kiện: ".length).trim();
              if (echoedQuery == message.trim()) {
                print('Detected echo response, generating meaningful response');
                aiResponse = _generateLocalResponse(message);
              }
            }

            // Complete with the real response if we haven't timed out yet
            if (!responseCompleter.isCompleted) {
              responseCompleter.complete(aiResponse);
            } else if (hasTimedOut) {
              // If we already timed out but now got a real response, update the history
              print('Response arrived after timeout, updating history');
              // Replace the timeout message with the actual response in history
              sendChatMessage(message, aiResponse);
            }
          } catch (e) {
            print('JSON parse error: $e');
            final fallbackResponse = "Lỗi xử lý phản hồi từ máy chủ: $e";

            if (!responseCompleter.isCompleted) {
              responseCompleter.complete(fallbackResponse);
            }
          }
        } else {
          final errorResponse = "Lỗi từ máy chủ: ${response.statusCode}";

          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(errorResponse);
          }
        }
      }).catchError((error) {
        print('HTTP request error: $error');
        final errorResponse = "Lỗi kết nối: $error";

        if (!responseCompleter.isCompleted) {
          responseCompleter.complete(errorResponse);
        }
      });

      // Wait for either the timeout or the response
      return await responseCompleter.future;
    } catch (e) {
      print('Error in sendMessage: $e');

      // Generate a fallback response based on the query
      String fallbackResponse = _generateLocalResponse(message);

      // Save fallback response to history
      await sendChatMessage(message, fallbackResponse);

      return fallbackResponse;
    }
  }

  // Helper method to check if a command is likely a Kubernetes command
  bool _isKubernetesCommand(String command) {
    final kubeCommands = [
      'kubectl',
      'k8s',
      'kubernetes',
      'minikube',
      'helm',
      'pod',
      'pods',
      'node',
      'nodes',
      'deployment',
      'service',
      'cluster',
      'namespace'
    ];

    final lowerCommand = command.toLowerCase();
    return kubeCommands.any((cmd) => lowerCommand.contains(cmd));
  }

  // Helper method to check if a query is related to a spiritual or ghost topic
  bool _isGhostRelatedQuery(String query) {
    final spiritualKeywords = ['ma', 'quỷ', 'tâm linh', 'chuyện ma'];
    for (var keyword in spiritualKeywords) {
      if (query.toLowerCase().contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  // Helper method to get a Kubernetes-specific fallback response
  String _getKubernetesFallbackResponse(String query) {
    return "Để kiểm tra pod trong Kubernetes, bạn có thể sử dụng các lệnh sau:\n\n"
        "1. `kubectl get pods` - Liệt kê tất cả pods\n"
        "2. `kubectl describe pod <tên-pod>` - Xem thông tin chi tiết về pod\n"
        "3. `kubectl logs <tên-pod>` - Xem logs của pod\n\n"
        "Hiện tôi không thể kết nối với máy chủ Kubernetes, nhưng những lệnh trên sẽ giúp bạn bắt đầu.";
  }

  // Helper method to get a general fallback response
  String _getGeneralFallbackResponse(String query) {
    return "Tôi không thể kết nối với máy chủ AI để xử lý yêu cầu của bạn. "
        "Vui lòng thử lại sau hoặc kiểm tra kết nối mạng.";
  }

  // Thực thi workflow step
  Future<String> executeWorkflowStep(String step, String token) async {
    if (token.isEmpty) {
      return "Vui lòng đăng nhập để thực thi lệnh.";
    }

    // First check if server is reachable
    bool isServerConnected = await _checkServerConnection();
    if (!isServerConnected) {
      // For kubernetes commands, provide simulated response
      if (_isKubernetesCommand(step)) {
        return _simulateKubernetesCommand(step);
      }

      // For general commands, provide a message about connectivity
      return "Không thể kết nối với máy chủ để thực thi lệnh. Vui lòng kiểm tra kết nối mạng và thử lại sau.";
    }

    // Counter for retries
    int retryAttempts = 0;
    const maxRetries = 3;

    while (retryAttempts <= maxRetries) {
      try {
        // Increase timeout for possible Kubernetes commands
        final timeout = _isKubernetesCommand(step)
            ? AppConfig.kubernetesCommandTimeout
            : Duration(seconds: 30);

        // Lấy URL từ cấu hình
        final String apiUrl = '${AppConfig.apiUrl}/command';
        print(
            'Executing command: $step (attempt ${retryAttempts + 1}/${maxRetries + 1})');

        // Tạo request body
        final Map<String, dynamic> requestBody = {
          'command': step,
        };

        final response = await http
            .post(
              Uri.parse(apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(timeout);

        // Log response for debugging
        print('Execute workflow step response: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          try {
            // Properly decode with UTF-8 handling
            final String utf8Body = utf8.decode(response.bodyBytes);
            final jsonResponse = json.decode(utf8Body);
            String output =
                jsonResponse['output'] ?? "Lệnh thực thi thành công";
            return output;
          } catch (parseError) {
            print('JSON parsing error: $parseError');
            // If JSON parsing fails, return raw response if possible
            if (response.body.isNotEmpty) {
              return "Thực thi thành công nhưng không thể xử lý kết quả: ${response.body}";
            } else {
              return "Thực thi thành công.";
            }
          }
        } else if (response.statusCode == 408 || response.statusCode == 504) {
          // Timeout errors - consider retrying
          if (retryAttempts < maxRetries) {
            retryAttempts++;
            // Exponential backoff: 2s, 4s, 8s
            final backoffDuration = Duration(seconds: 2 * (1 << retryAttempts));
            print(
                'Request timed out. Retrying after ${backoffDuration.inSeconds}s...');
            await Future.delayed(backoffDuration);
            continue;
          } else {
            // If all retries timed out and this is a Kubernetes command, use simulation
            if (_isKubernetesCommand(step)) {
              print('All retries timed out. Using Kubernetes simulation.');
              return _simulateKubernetesCommand(step);
            }
            return "Lỗi: Thao tác mất quá nhiều thời gian. Vui lòng thử cách khác hoặc chia nhỏ nhiệm vụ.";
          }
        } else {
          try {
            final String utf8Body = utf8.decode(response.bodyBytes);
            final errorJson = json.decode(utf8Body);
            String errorMsg = errorJson['error'] ?? "Lỗi không xác định";
            return "Lỗi: $errorMsg (${response.statusCode})";
          } catch (parseError) {
            return "Lỗi: Không thể thực thi lệnh (${response.statusCode})";
          }
        }
      } on TimeoutException {
        if (retryAttempts < maxRetries) {
          retryAttempts++;
          // Exponential backoff: 2s, 4s, 8s
          final backoffDuration = Duration(seconds: 2 * (1 << retryAttempts));
          print(
              'Request timed out. Retrying after ${backoffDuration.inSeconds}s...');
          await Future.delayed(backoffDuration);
          continue;
        }

        // If all retries failed, use local simulation as a fallback
        if (_isKubernetesCommand(step)) {
          print(
              'Server communication failed, using local Kubernetes simulation');
          return _simulateKubernetesCommand(step);
        }

        return "Lỗi: Thao tác mất quá nhiều thời gian. Có thể lệnh Kubernetes của bạn cần thời gian dài để hoàn thành.";
      } catch (e) {
        if (retryAttempts < maxRetries && _isRetryableError(e)) {
          retryAttempts++;
          // Exponential backoff: 2s, 4s, 8s
          final backoffDuration = Duration(seconds: 2 * (1 << retryAttempts));
          print(
              'Network error: $e. Retrying after ${backoffDuration.inSeconds}s...');
          await Future.delayed(backoffDuration);
          continue;
        }

        // If connection fails completely, use local simulation for Kubernetes commands
        if (_isKubernetesCommand(step)) {
          print(
              'Server communication failed, using local Kubernetes simulation');
          return _simulateKubernetesCommand(step);
        }

        return "Lỗi: ${e.toString()}";
      }
    }

    // If all retries failed, try local simulation
    if (_isKubernetesCommand(step)) {
      print('All server requests failed, using local Kubernetes simulation');
      return _simulateKubernetesCommand(step);
    }

    return "Lỗi: Không thể thực thi lệnh sau nhiều lần thử.";
  }

  // Helper to check if an error is retryable
  bool _isRetryableError(Object e) {
    final errorMessage = e.toString().toLowerCase();
    return errorMessage.contains('socket') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('network') ||
        errorMessage.contains('timeout');
  }

  // Simulate running a Kubernetes command locally when server is unavailable
  String _simulateKubernetesCommand(String command) {
    print('Simulating Kubernetes command: $command');

    // Extract the command type
    final lowerCommand = command.toLowerCase();

    // Normalize any whitespace
    final normalizedCommand = command.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Simulate different kubectl commands
    if (lowerCommand.contains('get pods') || lowerCommand.contains('get pod')) {
      return _simulateGetPods(normalizedCommand);
    } else if (lowerCommand.contains('describe pod')) {
      return _simulateDescribePod(normalizedCommand);
    } else if (lowerCommand.contains('logs')) {
      return _simulatePodLogs(normalizedCommand);
    } else if (lowerCommand.contains('get nodes') ||
        lowerCommand.contains('get node')) {
      return _simulateGetNodes();
    } else if (lowerCommand.contains('get services') ||
        lowerCommand.contains('get svc')) {
      return _simulateGetServices();
    } else if (lowerCommand.contains('get deployments') ||
        lowerCommand.contains('get deploy')) {
      return _simulateGetDeployments();
    } else {
      return "Lưu ý: Đây là kết quả mô phỏng do không thể kết nối đến máy chủ.\n\n"
          "Không thể mô phỏng lệnh '$command'.\n"
          "Vui lòng kiểm tra kết nối mạng hoặc thử lại sau.";
    }
  }

  String _simulateGetPods(String command) {
    return "Lưu ý: Đây là kết quả mô phỏng do không thể kết nối đến máy chủ.\n\n"
        "NAME                                    READY   STATUS    RESTARTS   AGE\n"
        "botkube-788f5b7884-x7bfk               1/1     Running   0          2d\n"
        "nginx-deployment-66b6c48dd5-9zdnx      1/1     Running   0          1d\n"
        "nginx-deployment-66b6c48dd5-fg8vh      1/1     Running   0          1d\n"
        "postgres-5b7f94fcc9-mj52j              1/1     Running   0          5d\n"
        "prometheus-deployment-fcd577b9c-tp8xq  1/1     Running   0          3d";
  }

  String _simulateDescribePod(String command) {
    // Try to extract pod name from command
    String podName = "example-pod";
    final nameMatch = RegExp(r'pod\s+([a-zA-Z0-9_.-]+)').firstMatch(command);
    if (nameMatch != null && nameMatch.groupCount >= 1) {
      podName = nameMatch.group(1) ?? podName;
    }

    return "Lưu ý: Đây là kết quả mô phỏng do không thể kết nối đến máy chủ.\n\n"
        "Name:             $podName\n"
        "Namespace:        default\n"
        "Priority:         0\n"
        "Service Account:  default\n"
        "Node:             minikube/192.168.49.2\n"
        "Start Time:       Wed, 10 May 2023 08:30:00 +0700\n"
        "Labels:           app=$podName\n"
        "Status:           Running\n"
        "IP:               10.244.0.15\n"
        "Containers:\n"
        "  container-name:\n"
        "    Container ID:  docker://abc123\n"
        "    Image:         nginx:latest\n"
        "    Image ID:      docker-pullable://nginx@sha256:123456\n"
        "    Port:          80/TCP\n"
        "    Host Port:     0/TCP\n"
        "    State:         Running\n"
        "    Ready:         True\n"
        "    Restart Count: 0\n"
        "    Requests:\n"
        "      cpu:        100m\n"
        "      memory:     128Mi\n"
        "    Environment:  <none>\n"
        "    Mounts:\n"
        "      /var/run/secrets/kubernetes.io/serviceaccount from default-token-xyz (ro)";
  }

  String _simulatePodLogs(String command) {
    // Try to extract pod name from command
    String podName = "example-pod";
    final nameMatch = RegExp(r'logs\s+([a-zA-Z0-9_.-]+)').firstMatch(command);
    if (nameMatch != null && nameMatch.groupCount >= 1) {
      podName = nameMatch.group(1) ?? podName;
    }

    return "Lưu ý: Đây là kết quả mô phỏng do không thể kết nối đến máy chủ.\n\n"
        "2023-05-10T08:30:01.123Z INFO  Server started\n"
        "2023-05-10T08:30:02.234Z INFO  Connected to database\n"
        "2023-05-10T08:30:05.345Z INFO  Processed request from 10.0.0.1\n"
        "2023-05-10T08:30:10.456Z INFO  Health check passed\n"
        "2023-05-10T08:30:15.567Z INFO  Received API request /api/v1/status\n"
        "2023-05-10T08:30:20.678Z INFO  Cache updated\n"
        "2023-05-10T08:30:25.789Z INFO  Background task completed\n"
        "2023-05-10T08:30:30.890Z INFO  Processed request from 10.0.0.2";
  }

  String _simulateGetNodes() {
    return "Lưu ý: Đây là kết quả mô phỏng do không thể kết nối đến máy chủ.\n\n"
        "NAME       STATUS   ROLES                  AGE    VERSION\n"
        "minikube   Ready    control-plane,master   45d    v1.25.3\n"
        "worker-1   Ready    worker                 44d    v1.25.3\n"
        "worker-2   Ready    worker                 44d    v1.25.3";
  }

  String _simulateGetServices() {
    return "Lưu ý: Đây là kết quả mô phỏng do không thể kết nối đến máy chủ.\n\n"
        "NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE\n"
        "kubernetes          ClusterIP   10.96.0.1        <none>        443/TCP        45d\n"
        "nginx-service       NodePort    10.106.145.116   <none>        80:30080/TCP   15d\n"
        "postgres-service    ClusterIP   10.99.24.128     <none>        5432/TCP       30d\n"
        "prometheus-service  NodePort    10.102.68.111    <none>        9090:30090/TCP 20d";
  }

  String _simulateGetDeployments() {
    return "Lưu ý: Đây là kết quả mô phỏng do không thể kết nối đến máy chủ.\n\n"
        "NAME                 READY   UP-TO-DATE   AVAILABLE   AGE\n"
        "nginx-deployment     2/2     2            2           30d\n"
        "postgres             1/1     1            1           30d\n"
        "prometheus           1/1     1            1           20d\n"
        "botkube              1/1     1            1           15d";
  }

  // Helper to check if response is just echoing back the question
  bool _isEchoResponse(String question, String response) {
    // Remove common prefixes that might appear in AI responses
    String cleanedResponse = response
        .replaceAll(
            RegExp(
                r'^(Phân tích sự kiện:|Event analysis:|Phân tích:|Analysis:)'),
            '')
        .trim();

    // Case 1: Direct repetition - AI just echoes the question
    if (cleanedResponse == question) {
      return true;
    }

    // Case 2: If response contains most of the question as its content
    if (question.length > 10 &&
        cleanedResponse.contains(question.substring(0, question.length - 3))) {
      return true;
    }

    // Case 3: "Processing timeout" or similar errors
    if (cleanedResponse.contains('quá thời gian') ||
        cleanedResponse.contains('timeout') ||
        cleanedResponse.contains('I want to check pod') ||
        cleanedResponse.contains('muốn kiểm tra pod')) {
      return true;
    }

    return false;
  }
}
