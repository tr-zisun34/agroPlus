import 'package:flutter/material.dart';

import 'chat_provider.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAgent = message.isFromAgent;

    final bubbleColor = isAgent ? colorScheme.surfaceContainerHighest : colorScheme.primary;
    final textColor = isAgent ? colorScheme.onSurfaceVariant : colorScheme.onPrimary;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isAgent ? 4 : 16),
      bottomRight: Radius.circular(isAgent ? 16 : 4),
    );

    return Align(
      alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bubbleColor, borderRadius: borderRadius),
        child: Text(message.text, style: TextStyle(color: textColor)),
      ),
    );
  }
}
