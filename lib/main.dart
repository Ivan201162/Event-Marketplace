import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/performance_optimizer.dart';
import 'firebase_options.dart';
import 'generated/l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'router/enhanced_router.dart';
import 'services/analytics_service.dart';
import 'services/cache_service.dart';
import 'services/reminder_service.dart';
import 'services/test_data_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Инициализация оптимизатора производительности
    try {
      await PerformanceOptimizer.initialize();
    } on Exception catch (e) {
      debugPrint('Ошибка инициализации PerformanceOptimizer: $e');
    }

    // Инициализация Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase инициализирован успешно');
      
      // Инициализация аналитики
      final analyticsService = AnalyticsService();
      await analyticsService.logScreenView('app_start');
      debugPrint('Firebase Analytics инициализирован успешно');
    } on Exception catch (e) {
      debugPrint('Ошибка инициализации Firebase: $e');
      // Продолжаем без Firebase для отладки
    }

    // Инициализация сервиса уведомлений
    try {
      // await NotificationService().initialize();
    } on Exception catch (e) {
      debugPrint('Ошибка инициализации NotificationService: $e');
    }

    // Инициализация сервиса напоминаний
    try {
      await ReminderService().initialize();
    } on Exception catch (e) {
      debugPrint('Ошибка инициализации ReminderService: $e');
    }

    // Инициализация сервиса кэширования
    try {
      await CacheService().initialize();
    } on Exception catch (e) {
      debugPrint('Ошибка инициализации CacheService: $e');
    }

    // Инициализация тестовых данных
    await _initializeTestData();

    runApp(const ProviderScope(child: EventMarketplaceApp()));
  } catch (e, stackTrace) {
    debugPrint('Критическая ошибка при запуске приложения: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Запускаем минимальную версию приложения
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Ошибка инициализации приложения'),
        ),
      ),
    ),);
  }
}

/// Инициализация тестовых данных
Future<void> _initializeTestData() async {
  try {
    debugPrint('Начинаем инициализацию тестовых данных...');
    final testDataService = TestDataService();
    
    // Проверяем наличие данных с таймаутом
    final hasData = await testDataService.hasTestData().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Таймаут при проверке тестовых данных');
        return false;
      },
    );

    if (!hasData) {
      debugPrint('Загружаем тестовые данные...');
      await testDataService.populateAll().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Таймаут при загрузке тестовых данных');
        },
      );
      debugPrint('Тестовые данные загружены успешно');
    } else {
      debugPrint('Тестовые данные уже загружены');
    }
  } catch (e, stackTrace) {
    debugPrint('Ошибка при инициализации тестовых данных: $e');
    debugPrint('Stack trace: $stackTrace');
    // Не прерываем запуск приложения из-за ошибки тестовых данных
  }
}

class EventMarketplaceApp extends ConsumerWidget {
  const EventMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final router = EnhancedRouter.router;

    return MaterialApp.router(
      title: 'Event Marketplace',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
        Locale('kk'),
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
