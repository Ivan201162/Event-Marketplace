import 'package:event_marketplace_app/screens/enhanced_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Оптимизированный главный экран с ленивой загрузкой
class OptimizedMainScreen extends ConsumerWidget {
  const OptimizedMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const EnhancedMainScreen();
}
