import 'package:flutter/material.dart';

// Message status enum
enum MessageStatus {
  sending,
  delivered,
  error,
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String sender;
  final MessageStatus status;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.sender,
    this.status = MessageStatus.delivered,
  });

  // Create a copy with updated properties
  ChatMessage copyWith({
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? sender,
    MessageStatus? status,
  }) {
    return ChatMessage(
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      sender: sender ?? this.sender,
      status: status ?? this.status,
    );
  }

  // Convert from a JSON map
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sender: json['sender'] as String,
      status: MessageStatus.values[(json['status'] as int?) ?? 1],
    );
  }

  // Convert to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'sender': sender,
      'status': status.index,
    };
  }
}
