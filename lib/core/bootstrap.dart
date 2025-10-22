import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../firebase_options.dart';
import '../services/fcm_service.dart';
import '../services/push_notification_service.dart';

/// Bootstrap class for safe app initialization
class Bootstrap {
  static const Duration _initTimeout = Duration(seconds: 8);
  static const Duration _firebaseTimeout = Duration(seconds: 5);

  /// Initialize the app with timeout and error handling
  static Future<void> initialize() async {
    try {
      debugPrint('🔄 Bootstrap: Начинаем инициализацию...');
      
      // Set up error handling first
      debugPrint('🔄 Bootstrap: Настройка обработки ошибок...');
      _setupErrorHandling();

      // Initialize Firebase with timeout
      debugPrint('🔄 Bootstrap: Инициализация Firebase...');
      await _initializeFirebase();

      // Initialize other services
      debugPrint('🔄 Bootstrap: Инициализация сервисов...');
      await _initializeServices();

      // Initialize FCM
      debugPrint('🔄 Bootstrap: Инициализация FCM...');
      await _initializeFCM();

      // Initialize Push Notifications
      debugPrint('🔄 Bootstrap: Инициализация Push Notifications...');
      await _initializePushNotifications();

      debugPrint('✅ Bootstrap: App initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Bootstrap: Initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');

      // Report to Crashlytics if available
      try {
        if (FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
          FirebaseCrashlytics.instance.recordError(e, stackTrace);
        }
      } catch (_) {
        debugPrint('⚠️ Bootstrap: Не удалось отправить ошибку в Crashlytics');
      }

      // Re-throw to be handled by main
      rethrow;
    }
  }

  /// Set up global error handling
  static void _setupErrorHandling() {
    // Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('🚨 Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');

      // Report to Crashlytics
      if (FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }

      // In debug mode, show error dialog
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // Platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('🚨 Platform Error: $error');
      debugPrint('Stack trace: $stack');

      // Report to Crashlytics
      if (FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
        FirebaseCrashlytics.instance.recordError(error, stack);
      }

      return true;
    };

    // Error widget builder
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Произошла ошибка',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  kDebugMode ? details.exception.toString() : 'Попробуйте перезапустить приложение',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart app
                    exit(0);
                  },
                  child: const Text('Перезапустить'),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }

  /// Initialize Firebase with timeout
  static Future<void> _initializeFirebase() async {
    try {
      // Check if Firebase is already initialized (robust check)
      try {
        Firebase.app();
        debugPrint('✅ Firebase already initialized');
        return;
      } catch (_) {
        // Not initialized yet
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(_firebaseTimeout);

      // Initialize Crashlytics
      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      }

      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      final message = e.toString();
      // If duplicate app, consider Firebase as already initialized and continue
      if (message.contains('duplicate-app') ||
          message.contains('A Firebase App named "[DEFAULT]" already exists')) {
        debugPrint('ℹ️ Firebase already initialized (duplicate-app), continuing.');
        return;
      }
      rethrow;
    }
  }

  /// Initialize other services
  static Future<void> _initializeServices() async {
    try {
      // Get package info
      final packageInfo = await PackageInfo.fromPlatform();
      debugPrint('📱 App version: ${packageInfo.version} (${packageInfo.buildNumber})');

      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      debugPrint('✅ Services initialized successfully');
    } catch (e) {
      debugPrint('❌ Services initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize FCM
  static Future<void> _initializeFCM() async {
    try {
      await FCMService.initialize();
      debugPrint('✅ FCM initialized successfully');
    } catch (e) {
      debugPrint('❌ FCM initialization failed: $e');
      // Не прерываем инициализацию приложения из-за ошибки FCM
    }
  }

  /// Initialize Push Notifications
  static Future<void> _initializePushNotifications() async {
    try {
      await PushNotificationService.initialize();
      debugPrint('✅ Push Notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Push Notifications initialization failed: $e');
      // Не прерываем инициализацию приложения из-за ошибки Push Notifications
    }
  }

  /// Get app info for debugging
  static Future<Map<String, String>> getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
        'appName': packageInfo.appName,
      };
    } catch (e) {
      debugPrint('❌ Failed to get app info: $e');
      return {};
    }
  }
}
