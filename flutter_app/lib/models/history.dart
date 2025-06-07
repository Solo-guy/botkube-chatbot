class HistoryEntry {
  final String id;
  final String userId;
  final String message;
  final String response;
  final DateTime timestamp;
  final double cost;

  HistoryEntry({
    required this.id,
    required this.userId,
    required this.message,
    required this.response,
    required this.timestamp,
    required this.cost,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'] != null
        ? json['id'].toString()
        : json['_id']?.toString() ?? '';

    print('Parsed history entry ID: $id');

    final userId = json['user_id']?.toString() ?? '';
    final message = json['message']?.toString() ?? '';
    final response = json['response']?.toString() ?? '';

    return HistoryEntry(
      id: id,
      userId: userId,
      message: message,
      response: response,
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      cost: (json['cost'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'message': message,
        'response': response,
        'timestamp': timestamp.toIso8601String(),
        'cost': cost,
      };
}
