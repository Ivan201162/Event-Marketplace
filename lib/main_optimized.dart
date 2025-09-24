import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_theme.dart';
import 'core/logger.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_routes.dart';
import 'core/feature_flags.dart';
import 'core/i18n/app_localizations.dart';
import 'core/build_optimizations.dart';
import 'core/performance_optimizations.dart';
import 'providers/theme_provider.dart';
import 'providers/performance_provider.dart';
import 'providers/image_cache_provider.dart';
import 'firebase_options.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/booking_form_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/specialists_screen.dart';
import 'screens/events_screen.dart';
import 'screens/ideas_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/performance_monitor.dart';

/// Оптимизированная точка входа в приложение
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация оптимизаций
  await _initializeOptimizations();

  // Инициализация Firebase
  await _initializeFirebase();

  // Инициализация приложения
  await _initializeApp();

  // Запуск приложения
  runApp(
    ProviderScope(
      child: const OptimizedEventMarketplaceApp(),
    ),
  );
}

/// Инициализация оптимизаций
Future<void> _initializeOptimizations() async {
  // Инициализация оптимизаций сборки
  BuildOptimizations.initializeReleaseOptimizations();

  // Инициализация оптимизаций производительности
  PerformanceOptimizations.initialize();

  // Инициализация оптимизаций для платформы
  BuildOptimizations.initializePlatformOptimizations();
}

/// Инициализация Firebase
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Инициализация Crashlytics
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Инициализация Performance Monitoring
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

    Logger.info('Firebase initialized successfully');
  } catch (e) {
    Logger.error('Failed to initialize Firebase: $e');
  }
}

/// Инициализация приложения
Future<void> _initializeApp() async {
  try {
    // Инициализация SharedPreferences
    await SharedPreferences.getInstance();

    // Инициализация локализации
    await AppLocalizations.initialize();

    Logger.info('App initialized successfully');
  } catch (e) {
    Logger.error('Failed to initialize app: $e');
  }
}

/// Оптимизированное приложение Event Marketplace
class OptimizedEventMarketplaceApp extends ConsumerWidget {
  const OptimizedEventMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final performanceState = ref.watch(performanceProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _createRouter(),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            // Монитор производительности (только в debug режиме)
            if (kDebugMode)
              const PerformanceMonitor(
                showDetails: true,
                position: PerformanceMonitorPosition.topRight,
              ),
          ],
        );
      },
    );
  }

  /// Создание роутера
  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.auth,
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.specialists,
          builder: (context, state) => const SpecialistsScreen(),
        ),
        GoRoute(
          path: AppRoutes.events,
          builder: (context, state) => const EventsScreen(),
        ),
        GoRoute(
          path: AppRoutes.ideas,
          builder: (context, state) => const IdeasScreen(),
        ),
        GoRoute(
          path: AppRoutes.chat,
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: AppRoutes.booking,
          builder: (context, state) => const BookingFormScreen(),
        ),
        GoRoute(
          path: AppRoutes.admin,
          builder: (context, state) => const AdminPanelScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }
}

/// Оптимизированный экран для тестирования производительности
class PerformanceTestScreen extends ConsumerWidget {
  const PerformanceTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceState = ref.watch(performanceProvider);
    final recommendations = ref.watch(optimizationRecommendationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест производительности'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статистика производительности
            const PerformanceStats(),
            const SizedBox(height: 16),

            // Рекомендации по оптимизации
            if (recommendations.isNotEmpty) ...[
              const OptimizationRecommendations(),
              const SizedBox(height: 16),
            ],

            // Управление оптимизацией
            const OptimizationControls(),
            const SizedBox(height: 16),

            // Кнопки для тестирования
            _buildTestButtons(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Тестирование',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _testImageLoading(ref),
              child: const Text('Тест загрузки изображений'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _testMemoryUsage(ref),
              child: const Text('Тест использования памяти'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _testScrollPerformance(ref),
              child: const Text('Тест производительности скролла'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _testNetworkRequests(ref),
              child: const Text('Тест сетевых запросов'),
            ),
          ],
        ),
      ],
    );
  }

  void _testImageLoading(WidgetRef ref) {
    // Тест загрузки изображений
    final imageCacheProvider = ref.read(imageCacheProvider);
    imageCacheProvider.initializeCache();
  }

  void _testMemoryUsage(WidgetRef ref) {
    // Тест использования памяти
    final performanceNotifier = ref.read(performanceProvider.notifier);
    performanceNotifier.forceCleanup();
  }

  void _testScrollPerformance(WidgetRef ref) {
    // Тест производительности скролла
    // Здесь можно добавить логику для тестирования скролла
  }

  void _testNetworkRequests(WidgetRef ref) {
    // Тест сетевых запросов
    // Здесь можно добавить логику для тестирования сетевых запросов
  }
}
