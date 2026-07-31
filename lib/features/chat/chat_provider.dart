import 'package:flutter/foundation.dart';

class ChatMessage {
  const ChatMessage({required this.text, required this.isFromAgent, required this.timestamp});

  final String text;
  final bool isFromAgent;
  final DateTime timestamp;
}

class ChatProvider extends ChangeNotifier {
  ChatProvider({required String greeting, required this.placeholderReply}) {
    _messages.add(ChatMessage(text: greeting, isFromAgent: true, timestamp: DateTime.now()));
  }

  final String placeholderReply;
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool isAgentTyping = false;

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(ChatMessage(text: trimmed, isFromAgent: false, timestamp: DateTime.now()));
    isAgentTyping = true;
    notifyListeners();

    // No backend agent yet — placeholder response validates the UI flow end to end.
    await Future.delayed(const Duration(milliseconds: 600));

    _messages.add(ChatMessage(text: placeholderReply, isFromAgent: true, timestamp: DateTime.now()));
    isAgentTyping = false;
    notifyListeners();
  }
}
