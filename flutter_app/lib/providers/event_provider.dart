import 'package:flutter/material.dart';
import '../models/event.dart';
import '../api_service.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class EventProvider with ChangeNotifier {
  List<Event> _events = [];
  bool _isLoading = false;
  String _errorMessage = '';
  WebSocketChannel? _channel;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  EventProvider() {
    _initWebSocket();
  }

  void _initWebSocket() {
    try {
      _channel = ApiService().connectToWebSocket();
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            final event = Event.fromJson(data);
            _events.add(event);
            notifyListeners();
          } catch (e) {
            _errorMessage = 'Lỗi khi nhận sự kiện: $e';
            notifyListeners();
          }
        },
        onError: (error) {
          _errorMessage = 'Lỗi kết nối WebSocket: $error';
          notifyListeners();
        },
        onDone: () {
          _errorMessage = 'Kết nối WebSocket đã đóng';
          notifyListeners();
          // Thử kết nối lại sau 5 giây
          Future.delayed(Duration(seconds: 5), _initWebSocket);
        },
      );
    } catch (e) {
      _errorMessage = 'Lỗi khởi tạo WebSocket: $e';
      notifyListeners();
    }
  }

  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Hiện tại API có thể chưa có endpoint trả về danh sách sự kiện
      // Tạm thời sử dụng dữ liệu giả lập
      await Future.delayed(const Duration(seconds: 1));
      _events = [
        Event(
          type: 'Pod Creation',
          resource: 'Pod',
          name: 'nginx-deployment-123',
          namespace: 'default',
          cluster: 'k3s-cluster',
        ),
        Event(
          type: 'Pod Deletion',
          resource: 'Pod',
          name: 'nginx-deployment-456',
          namespace: 'default',
          cluster: 'k3s-cluster',
        ),
        Event(
          type: 'Deployment Update',
          resource: 'Deployment',
          name: 'frontend-app-789',
          namespace: 'frontend',
          cluster: 'k3s-cluster',
        ),
      ];
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Lỗi khi tải sự kiện: $e';
      _isLoading = false;
    }
    notifyListeners();
  }

  void clearEvents() {
    _events = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
