import 'package:event_marketplace_app/firebase_options.dart';
import 'package:event_marketplace_app/services/error_logging_service.dart';
import 'package:firebase_core/firebase_core.dart';

/// Скрипт для тестирования улучшенного ErrorLoggingService
Future<void> main() async {
  print('🚀 Запуск тестирования ErrorLoggingService...');

  try {
    // Инициализация Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase инициализирован');

    final errorLoggingService = ErrorLoggingService();

    // Тест логирования ошибок
    print('\n📝 Тестирование логирования ошибок...');
    for (var i = 0; i < 5; i++) {
      await errorLoggingService.logError(
        error: 'Test error $i',
        stackTrace: 'Test stack trace $i',
        userId: 'test_user_$i',
        screen: 'test_screen',
        action: 'test_action',
        additionalData: {'iteration': i},
      );
    }

    // Тест логирования предупреждений
    print('\n⚠️ Тестирование логирования предупреждений...');
    for (var i = 0; i < 3; i++) {
      await errorLoggingService.logWarning(
        warning: 'Test warning $i',
        userId: 'test_user_$i',
        screen: 'test_screen',
        action: 'test_action',
        additionalData: {'iteration': i},
      );
    }

    // Тест логирования производительности
    print('\n⚡ Тестирование логирования производительности...');
    for (var i = 0; i < 3; i++) {
      await errorLoggingService.logPerformance(
        operation: 'test_operation_$i',
        duration: Duration(milliseconds: 100 + i * 50),
        userId: 'test_user_$i',
        screen: 'test_screen',
        additionalData: {'iteration': i},
      );
    }

    // Получение статистики
    print('\n📊 Получение статистики логов...');
    final stats = await errorLoggingService.getLogStats();
    print('Статистика логов:');
    stats.forEach((key, value) {
      print('  $key: $value');
    });

    // Принудительная отправка всех логов
    print('\n🔄 Принудительная отправка всех логов...');
    await errorLoggingService.flushAllLogs();

    // Получение обновленной статистики
    print('\n📊 Обновленная статистика логов...');
    final updatedStats = await errorLoggingService.getLogStats();
    print('Обновленная статистика:');
    updatedStats.forEach((key, value) {
      print('  $key: $value');
    });

    print('\n✅ Тестирование завершено успешно!');
  } catch (e) {
    print('❌ Ошибка при тестировании: $e');
  }
}
