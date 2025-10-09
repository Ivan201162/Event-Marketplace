import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'enhanced_ideas_screen.dart';

/// Простой экран идей для демонстрации
class SimpleIdeasScreen extends ConsumerWidget {
  const SimpleIdeasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const EnhancedIdeasScreen();
  }
}
