import 'package:event_marketplace_app/screens/enhanced_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран ленты новостей и обновлений
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const EnhancedFeedScreen();
}
