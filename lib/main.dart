import 'dart:async';
import 'dart:io';

import 'package:event_marketplace_app/core/app_router_minimal_working.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:event_marketplace_app/theme/theme.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/core/build_version.dart';
import 'package:event_marketplace_app/providers/theme_provider.dart';
import 'package:event_marketplace_app/firebase_options.dart';
import 'package:event_marketplace_app/services/wipe_service.dart';
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

  // Настройка Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  debugLog('APP: BUILD OK $BUILD_VERSION');
  debugLog('APP_VERSION:6.3.0+38');

  // Жёсткий таймаут инициализации Firebase
  bool firebaseReady = false;
  try {
    await Future.any([
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      Future.delayed(const Duration(seconds: 8)),
    ]);
    // Проверяем, что Firebase действительно инициализирован
      try {
        Firebase.app();
      firebaseReady = true;
      debugPrint('SPLASH_FIREBASE_INIT_OK');
      } catch (_) {
      debugPrint('SPLASH_INIT_ERR:Firebase not initialized after timeout');
    }
  } catch (e, st) {
    debugPrint('SPLASH_INIT_ERR:$e\n$st');
    }
    
  // Fresh-install wipe (только для тест-устройства в release)
  if (firebaseReady) {
    try {
      await WipeService.maybeWipeOnFirstRun();
    } catch (e) {
      debugPrint('WIPE_SERVICE_ERROR:$e');
    }
    }

    runZonedGuarded(() {
    runApp(AppRoot(firebaseReady: firebaseReady));
    }, (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    });
}

/// Корневой виджет приложения
class AppRoot extends ConsumerWidget {
  final bool firebaseReady;

  const AppRoot({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Event Marketplace',
      theme: appLightTheme(),
      darkTheme: appDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
