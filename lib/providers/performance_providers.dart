import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Состояние производительности
class PerformanceState {
  const PerformanceState({
    this.fps = 60.0,
    this.memoryUsage = 0,
    this.cpuUsage = 0,
    this.isOptimized = false,
    this.optimizations = const [],
  });
  final double fps;
  final int memoryUsage;
  final int cpuUsage;
  final bool isOptimized;
  final List<String> optimizations;

  PerformanceState copyWith({
    double? fps,
    int? memoryUsage,
    int? cpuUsage,
    bool? isOptimized,
    List<String>? optimizations,
  }) => PerformanceState(
    fps: fps ?? this.fps,
    memoryUsage: memoryUsage ?? this.memoryUsage,
    cpuUsage: cpuUsage ?? this.cpuUsage,
    isOptimized: isOptimized ?? this.isOptimized,
    optimizations: optimizations ?? this.optimizations,
  );
}

/// Провайдер производительности
class PerformanceNotifier extends Notifier<PerformanceState> {
  PerformanceNotifier() : super() {
    _startMonitoring();
  }

  Timer? _monitoringTimer;

  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updatePerformanceMetrics();
    });
  }

  void _updatePerformanceMetrics() {
    // Здесь должна быть логика мониторинга производительности
    state = state.copyWith(
      fps: 60,
      memoryUsage: 100,
      cpuUsage: 50,
      isOptimized: true,
      optimizations: ['Image caching', 'List virtualization'],
    );
  }

  void optimizePerformance() {
    state = state.copyWith(
      isOptimized: true,
      optimizations: [...state.optimizations, 'Manual optimization'],
    );
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
  }
}

/// Провайдер производительности
final performanceProvider = NotifierProvider<PerformanceNotifier, PerformanceState>(
  (ref) => PerformanceNotifier(),
);
