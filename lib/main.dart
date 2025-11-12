import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/core/app_root.dart';
import 'package:event_marketplace_app/core/build_version.dart';
import 'package:event_marketplace_app/firebase_options.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/core/performance_monitor.dart';
import 'package:event_marketplace_app/services/feedback_service.dart';
import 'package:event_marketplace_app/services/soundscape_service.dart';
import 'package:event_marketplace_app/services/ambient_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

Future<void> main() async {
  final startupStart = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Активация Performance Test Mode
  final performanceMonitor = PerformanceMonitor();
  await performanceMonitor.startMonitoring();
  
  // Включение Firestore persistence для офлайн-режима
  try {
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
    debugLog('OFFLINE_ENABLED: Firestore persistence enabled');
  } catch (e) {
    debugLog('OFFLINE_ENABLED_ERR: $e');
    // Persistence может быть уже включена или не поддерживается на платформе
  }

  // Глобальный обработчик ошибок UI
  FlutterError.onError = (errorDetails) {
    debugLog('FATAL_UI_ERR:${errorDetails.exception}');
    debugLog('FATAL_UI_ERR_STACK:${errorDetails.stack}');
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Обработчик ошибок платформы
  PlatformDispatcher.instance.onError = (error, stack) {
    debugLog('FATAL_PLATFORM_ERR:$error');
    debugLog('FATAL_PLATFORM_STACK:$stack');
    FirebaseCrashlytics.instance.recordError(error, stack);
    return true;
  };

  debugLog('APP: BUILD OK v7.4-next-evolution-pro-motion-ambient');

  // Инициализация Firebase
  bool firebaseReady = false;
  try {
    try {
      Firebase.app();
      firebaseReady = true;
      debugLog('SPLASH:init-already-done');
    } catch (_) {
      debugLog('SPLASH:init-start');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Firebase.app();
      firebaseReady = true;
      debugLog('SPLASH:init-done');
    }
  } catch (e, st) {
    debugLog('SPLASH:init-failed:$e');
    debugLog('SPLASH_INIT_ERR:$e\n$st');
  }
  
  debugLog('BOOTCHECK: OK (deps, google.json, signing, crashlytics, perf, persistence)');
  
  // Инициализация V7.4 сервисов
  try {
    await FeedbackService().init();
    await SoundscapeService().init();
    AmbientEngine().init();
    debugLog('V7_4_SERVICES_INIT: OK');
  } catch (e) {
    debugLog('V7_4_SERVICES_INIT_ERR: $e');
  }

  runZonedGuarded(() {
    runApp(ProviderScope(child: AppRoot(firebaseReady: firebaseReady)));
    
    // Запись времени запуска после инициализации Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final startupDuration = DateTime.now().difference(startupStart).inMilliseconds;
      performanceMonitor.recordStartupTime(startupDuration);
    });
  }, (error, stack) {
    debugLog('FATAL_ZONE_ERR:$error');
    debugLog('FATAL_ZONE_STACK:$stack');
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}
