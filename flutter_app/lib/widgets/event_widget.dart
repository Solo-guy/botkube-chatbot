import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../api_service.dart';
import '../providers/event_provider.dart' as event_provider;
import 'chat_widget.dart';
import '../main.dart'; // Import để sử dụng GradientButton
import '../providers/chat_provider.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi fetchEvents từ provider khi widget được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<event_provider.EventProvider>(context, listen: false)
          .fetchEvents();
    });
  }

  Future<void> _fetchEvents() async {
    await Provider.of<event_provider.EventProvider>(context, listen: false)
        .fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sự Kiện Kubernetes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Consumer<event_provider.EventProvider>(
            builder: (context, eventProvider, child) {
              if (eventProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (eventProvider.errorMessage.isNotEmpty) {
                return Center(
                    child: Text(eventProvider.errorMessage,
                        style: const TextStyle(color: Colors.red)));
              } else if (eventProvider.events.isEmpty) {
                return const Center(
                    child: Text('Không có sự kiện nào để hiển thị.'));
              } else {
                return Expanded(
                  child: ListView.builder(
                    itemCount: eventProvider.events.length,
                    itemBuilder: (context, index) {
                      final event = eventProvider.events[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(event.type),
                          subtitle: Text(
                              '${event.resource} ${event.name} in ${event.namespace} on ${event.cluster}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.analytics),
                            onPressed: () {
                              // Gọi API phân tích sự kiện
                              try {
                                var chatProvider = Provider.of<ChatProvider>(
                                    context,
                                    listen: false);
                                chatProvider.addMessage(
                                    'Phân tích sự kiện: ${event.type} ${event.name}');
                                chatProvider.analyzeEvent(event);
                              } catch (e) {
                                print('Lỗi khi phân tích sự kiện: $e');
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          GradientButton(
            onPressed: _fetchEvents,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Text(
              'Làm mới sự kiện',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
