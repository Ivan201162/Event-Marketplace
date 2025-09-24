import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase_analytics_service.dart';

/// Провайдер для Firebase Analytics Service
final firebaseAnalyticsServiceProvider = Provider<FirebaseAnalyticsService>((ref) {
  return FirebaseAnalyticsService();
});

/// Провайдер для инициализации Firebase Analytics
final firebaseAnalyticsInitializationProvider = FutureProvider<void>((ref) async {
  final analyticsService = ref.read(firebaseAnalyticsServiceProvider);
  await analyticsService.initialize();
});
