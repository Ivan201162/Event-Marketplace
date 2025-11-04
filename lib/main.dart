import 'dart:async';

import 'package:event_marketplace_app/core/app_router_minimal_working.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:event_marketplace_app/core/bootstrap.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/core/build_version.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настройка Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  try {
    debugPrint('🚀 Запуск приложения...');

    // Инициализация Bootstrap с таймаутом
    await Bootstrap.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint(
            '⚠️ Bootstrap инициализация превысила таймаут, продолжаем...',);
      },
    );

    debugPrint('✅ Bootstrap инициализация завершена');
    debugLog('APP: BUILD OK v5.0-full-suite');

    runZonedGuarded(() {
      runApp(const ProviderScope(child: EventMarketplaceApp()));
    }, (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    });
  } catch (e, stackTrace) {
    debugPrint('❌ Критическая ошибка инициализации: $e');
    debugPrint('Stack trace: $stackTrace');

    // Отправляем ошибку в Crashlytics
    FirebaseCrashlytics.instance.recordError(e, stackTrace);

    // Запускаем приложение даже при ошибке инициализации
    runApp(const ProviderScope(child: EventMarketplaceApp()));
  }
}

class EventMarketplaceApp extends ConsumerWidget {
  const EventMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Event Marketplace',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
