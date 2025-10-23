import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'enhanced_chats_screen.dart';

/// Экран чатов с специалистами
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const EnhancedChatsScreen();
}
