import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';

class ChatMessage {
  const ChatMessage({required this.text, required this.isFromAgent, required this.timestamp});

  final String text;
  final bool isFromAgent;
  final DateTime timestamp;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['content'] as String,
      isFromAgent: json['role'] == 'assistant',
      timestamp: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ChatProvider extends ChangeNotifier {
  ChatProvider({required this.farmId, required this.greeting, required this.errorReply});

  final String farmId;
  final String greeting;
  final String errorReply;
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool isLoading = true;
  bool isAgentTyping = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.get('/farms/$farmId/chat/messages');
      final history = (response.data as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      if (history.isEmpty) {
        _messages.add(ChatMessage(text: greeting, isFromAgent: true, timestamp: DateTime.now()));
      } else {
        _messages.addAll(history);
      }
    } on DioException {
      _messages.add(ChatMessage(text: greeting, isFromAgent: true, timestamp: DateTime.now()));
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(ChatMessage(text: trimmed, isFromAgent: false, timestamp: DateTime.now()));
    isAgentTyping = true;
    notifyListeners();

    String replyText;
    try {
      final response = await ApiClient.instance.dio.post(
        '/farms/$farmId/chat',
        data: {"message": trimmed},
      );
      replyText = response.data['reply'] as String;
    } on DioException {
      replyText = errorReply;
    }

    _messages.add(ChatMessage(text: replyText, isFromAgent: true, timestamp: DateTime.now()));
    isAgentTyping = false;
    notifyListeners();
  }

  Future<bool> startNewConversation() async {
    try {
      await ApiClient.instance.dio.delete('/farms/$farmId/chat/messages');
    } on DioException {
      return false;
    }

    _messages.clear();
    _messages.add(ChatMessage(text: greeting, isFromAgent: true, timestamp: DateTime.now()));
    notifyListeners();
    return true;
  }
}
