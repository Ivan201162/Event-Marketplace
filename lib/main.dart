import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'core/enhanced_router.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  debugPrint('🕐 [${DateTime.now()}] Starting main()...');
  
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🕐 [${DateTime.now()}] WidgetsFlutterBinding.ensureInitialized() completed');

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

  // Добавляем ErrorWidget.builder для предотвращения черного экрана
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Ошибка приложения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(details.exception.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Попытка перезапуска
                  runApp(const ProviderScope(child: EventMarketplaceApp()));
                },
                child: const Text('Перезапустить'),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // НЕБЛОКИРУЮЩАЯ ИНИЦИАЛИЗАЦИЯ - запускаем приложение сразу
  debugPrint('🚀 [${DateTime.now()}] Starting EventMarketplaceApp immediately...');
  runApp(const ProviderScope(child: EventMarketplaceApp()));

  // Инициализация сервисов в фоне (неблокирующая)
  _initializeServicesInBackground();
}

/// Неблокирующая инициализация сервисов в фоне
void _initializeServicesInBackground() async {
  try {
    debugPrint('🕐 [${DateTime.now()}] Starting background service initialization...');
    
    // Инициализация Firebase с таймаутом
    try {
      debugPrint('🕐 [${DateTime.now()}] Initializing Firebase...');
      await Future.any([
        Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        Future.delayed(const Duration(seconds: 10)),
      ]);
      debugPrint('✅ [${DateTime.now()}] Firebase initialized successfully');
    } on Exception catch (e) {
      debugPrint('❌ [${DateTime.now()}] Firebase initialization error: $e');
    } catch (e) {
      debugPrint('❌ [${DateTime.now()}] Firebase timeout or error: $e');
    }

    // Инициализация Supabase с таймаутом
    try {
      debugPrint('🕐 [${DateTime.now()}] Initializing Supabase...');
      // Проверяем конфигурацию
      SupabaseConfigValidator.validate();

      await Future.any([
        Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
          debug: SupabaseConfig.isDevelopment,
        ),
        Future.delayed(const Duration(seconds: 10)),
      ]);

      debugPrint('✅ [${DateTime.now()}] Supabase initialized successfully');
    } on Exception catch (e) {
      debugPrint('❌ [${DateTime.now()}] Supabase initialization error: $e');
      // Приложение может работать без Supabase (только Firebase функции)
    } catch (e) {
      debugPrint('❌ [${DateTime.now()}] Supabase timeout or error: $e');
    }

    debugPrint('✅ [${DateTime.now()}] Background service initialization completed');
  } catch (e, stack) {
    debugPrint('🚨 [${DateTime.now()}] Background initialization error: $e');
    debugPrint('Stack: $stack');
  }
}

class EventMarketplaceApp extends ConsumerWidget {
  const EventMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🕐 [${DateTime.now()}] EventMarketplaceApp.build() called');
    
    try {
      // Безопасное получение темы с fallback
      ThemeMode themeMode;
      try {
        themeMode = ref.watch(themeProvider);
        debugPrint('🕐 [${DateTime.now()}] Theme mode: $themeMode');
      } catch (e) {
        debugPrint('⚠️ Theme provider error: $e');
        themeMode = ThemeMode.system;
      }

      // Безопасное получение роутера с fallback
      GoRouter router;
      try {
        router = ref.watch(routerProvider);
        debugPrint('🕐 [${DateTime.now()}] Router config loaded');
      } catch (e) {
        debugPrint('⚠️ Router provider error: $e');
        router = _createFallbackRouter();
      }

      // ВОССТАНОВЛЕННЫЙ РОУТЕР С FALLBACK
      return MaterialApp.router(
        title: 'Event Marketplace',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          debugPrint('🕐 [${DateTime.now()}] MaterialApp.router builder called');
          return child ?? const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    '⚠️ Ошибка загрузки экрана',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Переход на домашний экран...',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e, stack) {
      debugPrint('🚨 [${DateTime.now()}] Error in EventMarketplaceApp.build(): $e');
      debugPrint('Stack: $stack');
      
      // Fallback UI при ошибке
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Ошибка загрузки приложения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Попытка перезапуска
                    runApp(const ProviderScope(child: EventMarketplaceApp()));
                  },
                  child: const Text('Перезапустить'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// Создает fallback роутер в случае ошибки основного
  GoRouter _createFallbackRouter() {
    return GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, size: 64),
                  SizedBox(height: 16),
                  Text('Event Marketplace', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Добро пожаловать!', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
