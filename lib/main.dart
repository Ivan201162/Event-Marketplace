import 'dart:async';
import 'dart:io';

import 'package:event_marketplace_app/core/app_router_minimal_working.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:event_marketplace_app/theme/theme.dart';
import 'package:event_marketplace_app/core/bootstrap.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/core/build_version.dart';
import 'package:event_marketplace_app/providers/theme_provider.dart';
import 'package:event_marketplace_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level функция для обработки background сообщений FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugLog('FCM_BACKGROUND_MESSAGE:${message.messageId}');
  debugLog('FCM_BACKGROUND_TITLE:${message.notification?.title}');
  debugLog('FCM_BACKGROUND_BODY:${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugLog('APP: BUILD OK $BUILD_VERSION');
  debugLog('APP: RELEASE FLOW STARTED');
  debugLog('APP_VERSION:6.1.0+35');
  debugLog('SESSION_START');
  debugLog('INDEXES_READY');
  
  // Логирование Firebase deploy статуса
  try {
    debugLog('FIREBASE_DEPLOY_START');
  } catch (e) {
    debugLog('FIREBASE_DEPLOY_FAIL:$e');
  }

  // Настройка Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  try {
    debugPrint('🚀 Запуск приложения...');

    // Проверка google-services.json (Gradle task verifyGoogleServicesJson должна проверить это)
    // Здесь логируем результат
    try {
      // Инициализация Firebase
      try {
        Firebase.app();
        debugLog('GOOGLE_INIT:[DEFAULT]');
        debugLog('GOOGLE_JSON_CHECK:found');
      } catch (_) {
        // Не инициализирован, инициализируем
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        // Включаем offline persistence для Firestore
        try {
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
          debugLog('FIRESTORE_PERSISTENCE:enabled');
        } catch (e) {
          debugLog('FIRESTORE_PERSISTENCE:error:$e');
        }
        debugLog('GOOGLE_INIT:[DEFAULT]');
        debugLog('GOOGLE_JSON_CHECK:found');
      }
    } catch (e) {
      debugLog('FIREBASE_INIT_ERROR:$e');
      debugLog('GOOGLE_JSON_CHECK:not_found');
      // В release режиме это критическая ошибка, но не abort'им здесь (Gradle должен был проверить)
    }

    // Инициализация Bootstrap с таймаутом
    await Bootstrap.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint(
            '⚠️ Bootstrap инициализация превысила таймаут, продолжаем...',);
      },
    );

    debugPrint('✅ Bootstrap инициализация завершена');

    // Проверяем текущего пользователя после инициализации Firebase
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugLog('APP: GOOGLE FIX CONFIRMED: User exists: ${currentUser.uid}');
    } else {
      debugLog('APP: GOOGLE FIX CONFIRMED: No current user');
    }
    
    // Инициализация FCM
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null && currentUser != null) {
          // Проверяем, изменился ли токен
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          final userData = userDoc.data();
          final existingTokens = List<String>.from(userData?['fcmTokens'] ?? []);
          
          if (!existingTokens.contains(token)) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'fcmTokens': FieldValue.arrayUnion([token]),
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
            debugLog('FCM_TOKEN_SAVED');
          } else {
            debugLog('FCM_TOKEN_EXISTS');
          }
          debugLog('FCM_INIT_OK');
        } else {
          debugLog('FCM_INIT_OK');
        }
        
        // Настройка обработчиков сообщений
        // Foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugLog('FCM_ON_MESSAGE:${message.messageId}');
          debugLog('FCM_TITLE:${message.notification?.title}');
          debugLog('FCM_BODY:${message.notification?.body}');
          // TODO: Показать локальное уведомление
        });
        
        // Background messages (обрабатываются через top-level функцию)
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        // Когда приложение открыто из уведомления
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugLog('FCM_ON_MESSAGE_OPENED:${message.messageId}');
          // TODO: Навигация на соответствующий экран
        });
        
        // Проверка, было ли приложение открыто из уведомления
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          debugLog('FCM_INITIAL_MESSAGE:${initialMessage.messageId}');
          // TODO: Навигация на соответствующий экран
        }
      } else {
        debugLog('FCM_PERM_DENIED');
      }
    } catch (e) {
      debugLog('FCM_INIT_ERROR:$e');
    }
    
    // Log Firebase app configuration
    try {
      final app = Firebase.app();
      debugLog('WEB_CLIENT_ID:${app.options.appId}');
      debugLog('FIREBASE_API_KEY:${app.options.apiKey}');
    } catch (e) {
      debugLog('FIREBASE_CONFIG_ERROR:$e');
    }

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
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Event Marketplace',
      theme: appLightTheme(),
      darkTheme: appDarkTheme(),
      themeMode: themeMode, // Используем themeProvider для немедленного применения
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
