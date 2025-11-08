import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Упрощенный экран чата
class ChatScreenImproved extends ConsumerStatefulWidget {
  const ChatScreenImproved({
    required this.chatId, super.key,
  });
  final String chatId;

  @override
  ConsumerState<ChatScreenImproved> createState() => _ChatScreenImprovedState();
}

class _ChatScreenImprovedState extends ConsumerState<ChatScreenImproved> {
  @override
  void initState() {
    super.initState();
    debugLog("CHAT_OPENED:${widget.chatId}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чат ${widget.chatId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement chat options
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Чат',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Здесь будут отображаться сообщения',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
