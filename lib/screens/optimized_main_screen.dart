import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'enhanced_main_screen.dart';

/// Оптимизированный главный экран с ленивой загрузкой
class OptimizedMainScreen extends ConsumerWidget {
  const OptimizedMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const EnhancedMainScreen();
}
