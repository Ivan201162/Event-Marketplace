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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

  debugLog('APP: BUILD OK v7.2-premium');

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
    debugLog('SPLASH_INIT_ERR:$e\n$st');
  }

  runZonedGuarded(() {
    runApp(ProviderScope(child: AppRoot(firebaseReady: firebaseReady)));
  }, (error, stack) {
    debugLog('FATAL_ZONE_ERR:$error');
    debugLog('FATAL_ZONE_STACK:$stack');
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}
