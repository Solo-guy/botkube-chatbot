import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/history.dart';
import '../../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Import để sử dụng GradientButton
import 'chat_widget.dart'; // Import để sử dụng DialogButton
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _historyEntries = [];
  bool _isLoading = false;
  String _errorMessage = '';
  // Lưu tham chiếu đến ScaffoldMessengerState
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void initState() {
    super.initState();

    // Gọi _fetchHistory khi widget được khởi tạo
    _fetchHistory();

    // Đăng ký để làm mới dữ liệu khi widget trở thành active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('HistoryScreen đã được khởi tạo, đang tải lịch sử...');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lưu tham chiếu đến ScaffoldMessengerState
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  // Thêm phương thức để tải lại lịch sử - có thể gọi từ nút làm mới
  void refreshHistory() {
    print('Đang làm mới lịch sử...');
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }
      final apiService = Provider.of<ApiService>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      print(
          'HistoryWidget - Token: ${token.isNotEmpty ? 'Có token (${token.length} ký tự)' : 'Không có token'}');

      if (token.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Chưa đăng nhập. Vui lòng đăng nhập trước.';
            _isLoading = false;
          });
        }

        // Hiển thị dialog thông báo
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Chưa đăng nhập'),
              content: Text('Bạn cần đăng nhập để xem lịch sử.'),
              actions: <Widget>[
                DialogButton(
                  text: 'Đăng nhập',
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      try {
        // Thêm tham số time để tránh cache
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final entries =
            await apiService.getHistory(token, timestamp: timestamp);
        if (mounted) {
          setState(() {
            _historyEntries = entries;
            _isLoading = false;
          });
        }
        print('Đã tải lịch sử thành công: ${entries.length} mục');
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Lỗi khi tải lịch sử: $e';
            _isLoading = false;
          });
        }
        print('Lỗi khi tải lịch sử: $e');

        // Nếu lỗi là do token hết hạn, hiển thị thông báo để quay lại đăng nhập
        if (e.toString().contains('401') ||
            e.toString().contains('unauthorized') ||
            e.toString().contains('xác thực')) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Phiên đăng nhập hết hạn'),
                content: Text(
                    'Phiên đăng nhập của bạn đã hết hạn. Vui lòng đăng nhập lại.'),
                actions: <Widget>[
                  DialogButton(
                    text: 'Đăng nhập',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi cục bộ: $e';
          _isLoading = false;
        });
      }
      print('Lỗi cục bộ trong _fetchHistory: $e');
    }
  }

  // Phương thức hiển thị Snackbar an toàn
  void _showSnackBar({
    required String message,
    Color backgroundColor = Colors.green,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // Kiểm tra widget còn mounted không trước khi hiển thị
    if (!mounted) return;

    _scaffoldMessenger.hideCurrentSnackBar();
    _scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }

  // Thêm phương thức xóa một mục lịch sử
  Future<void> _deleteHistoryEntry(HistoryEntry entry) async {
    // Debug log
    print('Đang gửi yêu cầu xóa mục lịch sử với ID: ${entry.id}');

    // Xác nhận trước khi xóa
    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Xác nhận xóa'),
              content: Text(
                  'Bạn có chắc chắn muốn xóa mục lịch sử này?\n\nID: ${entry.id}'),
              actions: <Widget>[
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                DialogButton(
                  text: 'Xóa',
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      try {
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }
        final apiService = Provider.of<ApiService>(context, listen: false);
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token') ?? '';

        if (token.isEmpty) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Chưa đăng nhập. Vui lòng đăng nhập trước.';
              _isLoading = false;
            });
          }
          return;
        }

        final result = await apiService.deleteHistoryEntry(entry.id, token);

        // Kiểm tra widget còn mounted không
        if (!mounted) return;

        if (result['success'] == true) {
          // Xóa khỏi danh sách cục bộ nếu thành công
          if (mounted) {
            setState(() {
              _historyEntries.removeWhere((item) => item.id == entry.id);
              _isLoading = false;
            });
          }

          // Hiển thị thông báo xóa thành công
          _showSnackBar(
            message: result['message'] ?? 'Đã xóa mục lịch sử',
            backgroundColor: Colors.green,
          );
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }

          // Hiển thị thông báo lỗi chi tiết
          _showSnackBar(
            message: result['message'] ??
                'Không thể xóa mục lịch sử. Vui lòng thử lại sau.',
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                _deleteHistoryEntry(entry);
              },
            ),
          );

          // Log lỗi để debug
          print('Chi tiết lỗi: ${result.toString()}');
        }
      } catch (e) {
        // Kiểm tra widget còn mounted không
        if (!mounted) return;

        if (mounted) {
          setState(() {
            _errorMessage = 'Lỗi khi xóa lịch sử: $e';
            _isLoading = false;
          });
        }
        print('Lỗi khi xóa lịch sử: $e');

        // Hiển thị thông báo lỗi
        _showSnackBar(
          message: 'Lỗi khi xóa lịch sử: $e',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: () {
              _deleteHistoryEntry(entry);
            },
          ),
        );
      }
    }
  }

  // Thêm phương thức xóa toàn bộ lịch sử
  Future<void> _deleteAllHistory() async {
    // Xác nhận trước khi xóa toàn bộ
    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Xác nhận xóa tất cả'),
              content: Text(
                  'Bạn có chắc chắn muốn xóa TOÀN BỘ lịch sử chat?\n\nHành động này không thể phục hồi!'),
              actions: <Widget>[
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                DialogButton(
                  text: 'Xóa tất cả',
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      try {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _errorMessage = '';
          });
        }

        // Get the ChatProvider instance
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);

        // Use the ChatProvider's clearAllHistory method
        final success = await chatProvider.clearAllHistory();

        // Kiểm tra widget còn mounted không
        if (!mounted) return;

        if (success) {
          // Làm trống danh sách cục bộ
          if (mounted) {
            setState(() {
              _historyEntries.clear();
              _isLoading = false;
            });
          }

          // Hiển thị thông báo xóa thành công
          _showSnackBar(
            message: 'Đã xóa toàn bộ lịch sử chat và cập nhật giao diện',
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          );

          // Làm mới lại danh sách để đảm bảo UI đồng bộ với server
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _fetchHistory();
            }
          });
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }

          // Hiển thị thông báo lỗi
          _showSnackBar(
            message: 'Không thể xóa toàn bộ lịch sử. Vui lòng thử lại sau.',
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                _deleteAllHistory();
              },
            ),
          );
        }
      } catch (e) {
        // Kiểm tra widget còn mounted không
        if (!mounted) return;

        if (mounted) {
          setState(() {
            _errorMessage = 'Lỗi khi xóa toàn bộ lịch sử: $e';
            _isLoading = false;
          });
        }
        print('Lỗi khi xóa toàn bộ lịch sử: $e');

        // Hiển thị thông báo lỗi
        _showSnackBar(
          message: 'Lỗi khi xóa toàn bộ lịch sử: $e',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: () {
              _deleteAllHistory();
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with clear all button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch Sử Chat AI',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // Nút xóa toàn bộ lịch sử
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _deleteAllHistory,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_forever,
                              color: Colors.red, size: 24),
                          SizedBox(width: 4),
                          Text(
                            'Xóa tất cả',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(_errorMessage,
                          style: const TextStyle(color: Colors.red)))
                  : _historyEntries.isEmpty
                      ? const Center(
                          child: Text('Không có lịch sử chat nào để hiển thị.'))
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _historyEntries.length,
                            itemBuilder: (context, index) {
                              final entry = _historyEntries[index];
                              return _buildHistoryItem(entry);
                            },
                          ),
                        ),
          const SizedBox(height: 16),
          GradientButton(
            onPressed: refreshHistory,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Text(
              'Làm mới lịch sử',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Cập nhật Widget cho mỗi mục lịch sử trong ListView
  Widget _buildHistoryItem(HistoryEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with timestamp and delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd().add_jm().format(entry.timestamp),
                  style: TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
                // Delete button always visible
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Xóa mục lịch sử này',
                  onPressed: () => _deleteHistoryEntry(entry),
                ),
              ],
            ),
            Divider(),
            // Question from user
            Text(
              'Câu hỏi: ${entry.message}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            // AI Response
            Text(
              'Phản hồi: ${entry.response}',
              style: TextStyle(fontSize: 14.0),
            ),
            // Hidden ID text that shows on tap for debugging
            InkWell(
              onTap: () {
                // Show ID when tapped for debugging
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ID: ${entry.id}'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Xóa Ngay',
                      textColor: Colors.white,
                      onPressed: () {
                        _deleteHistoryEntry(entry);
                      },
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Nhấn để xem ID',
                  style: TextStyle(
                      fontSize: 10.0,
                      color: Colors.grey,
                      decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
