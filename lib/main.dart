import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'core/performance_optimizer.dart';
import 'firebase_options.dart';
import 'generated/l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart';
import 'services/test_data_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Инициализация оптимизатора производительности
    try {
      await PerformanceOptimizer.initialize();
    } catch (e) {
      print('Ошибка инициализации PerformanceOptimizer: $e');
    }

    // Инициализация Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase инициализирован успешно');
    } catch (e) {
      print('Ошибка инициализации Firebase: $e');
      // Продолжаем без Firebase для отладки
    }

    // Инициализация сервиса уведомлений
    try {
      await NotificationService().initialize();
    } catch (e) {
      print('Ошибка инициализации NotificationService: $e');
    }

    // Инициализация сервиса напоминаний
    try {
      await ReminderService().initialize();
    } catch (e) {
      print('Ошибка инициализации ReminderService: $e');
    }

    // Инициализация тестовых данных
    await _initializeTestData();

    runApp(const ProviderScope(child: EventMarketplaceApp()));
  } catch (e, stackTrace) {
    print('Критическая ошибка при запуске приложения: $e');
    print('Stack trace: $stackTrace');
    
    // Запускаем минимальную версию приложения
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Ошибка инициализации приложения'),
        ),
      ),
    ));
  }
}

/// Инициализация тестовых данных
Future<void> _initializeTestData() async {
  try {
    print('Начинаем инициализацию тестовых данных...');
    final testDataService = TestDataService();
    
    // Проверяем наличие данных с таймаутом
    final hasData = await testDataService.hasTestData().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('Таймаут при проверке тестовых данных');
        return false;
      },
    );

    if (!hasData) {
      print('Загружаем тестовые данные...');
      await testDataService.populateAll().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Таймаут при загрузке тестовых данных');
        },
      );
      print('Тестовые данные загружены успешно');
    } else {
      print('Тестовые данные уже загружены');
    }
  } catch (e, stackTrace) {
    print('Ошибка при инициализации тестовых данных: $e');
    print('Stack trace: $stackTrace');
    // Не прерываем запуск приложения из-за ошибки тестовых данных
  }
}

class EventMarketplaceApp extends ConsumerWidget {
  const EventMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Event Marketplace',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
