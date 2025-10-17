import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'core/enhanced_router.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
// import 'services/firestore_test_data_service.dart';
// import 'services/notification_service.dart';
// import 'services/analytics_service.dart';
// import 'services/growth_pack_integration_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настройка обработки ошибок
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("🔥 Flutter error: ${details.exception}");
    debugPrint("Stack: ${details.stack}");
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("🔥 Uncaught error: $error");
    debugPrint("Stack: $stack");
    return true;
  };

  try {
    debugPrint('🚀 Starting EventMarketplaceApp...');
    runApp(const ProviderScope(child: EventMarketplaceApp()));
    
    // Инициализация в фоне (не блокирует UI)
    _initializeServicesInBackground();
  } catch (e, stack) {
    debugPrint('🚨 Startup error: $e');
    debugPrint('Stack: $stack');

    // Запускаем приложение даже при ошибках инициализации
    runApp(const ProviderScope(child: EventMarketplaceApp()));
  }
}

// Инициализация сервисов в фоне
void _initializeServicesInBackground() async {
  try {
    // Инициализация Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } on Exception catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  try {
    // Инициализация Supabase
    SupabaseConfigValidator.validate();
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      debug: SupabaseConfig.isDevelopment,
    );
    debugPrint('✅ Supabase initialized successfully');
  } on Exception catch (e) {
    debugPrint('❌ Supabase initialization error: $e');
  }
}

class EventMarketplaceApp extends ConsumerWidget {
  const EventMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Event Marketplace',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
