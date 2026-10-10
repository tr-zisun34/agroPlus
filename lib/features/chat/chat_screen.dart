import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import 'chat_bubble.dart';
import 'chat_provider.dart';
import 'quick_chips.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.farmId, required this.farmName, this.autoSendMessage});

  final String farmId;
  final String farmName;
  final String? autoSendMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (_) => ChatProvider(
        farmId: farmId,
        greeting: l10n.chatGreeting(farmName),
        errorReply: l10n.chatErrorReply,
        autoSendMessage: autoSendMessage,
      )..load(),
      child: _ChatScreenBody(farmName: farmName),
    );
  }
}

class _ChatScreenBody extends StatefulWidget {
  const _ChatScreenBody({required this.farmName});

  final String farmName;

  @override
  State<_ChatScreenBody> createState() => _ChatScreenBodyState();
}

class _ChatScreenBodyState extends State<_ChatScreenBody> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _textController.clear();
  }

  Future<void> _startNewConversation() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.newConversationTitle),
        content: Text(l10n.newConversationContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.startButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<ChatProvider>().startNewConversation();
    if (!mounted || success) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.newConversationError)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.farmAssistantTitle, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  widget.farmName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _startNewConversation,
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: l10n.newConversationTooltip,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      return ChatBubble(message: message);
                    },
                  ),
          ),
          if (chatProvider.isAgentTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          const SizedBox(height: 8),
          QuickChips(onChipTap: _send),
          const SizedBox(height: 8),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: l10n.messageInputHint,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _send(_textController.text),
                    icon: const Icon(Icons.send),
                    tooltip: l10n.sendTooltip,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
