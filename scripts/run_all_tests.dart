import 'dart:io';

/// Скрипт для запуска всех тестов
void main() async {
  print('🧪 Запуск всех тестов...\n');

  // Список всех тестовых файлов
  final testFiles = [
    'test/integration/app_integration_test.dart',
    'test/widget/ui_test.dart',
    'test/performance/performance_test.dart',
    'test/firestore/firestore_test.dart',
    'test/navigation/navigation_test.dart',
    'test/responsive/responsive_test.dart',
    'test/automated/automated_test.dart',
  ];

  int passedTests = 0;
  int failedTests = 0;
  int totalTests = 0;

  for (final testFile in testFiles) {
    print('📋 Запуск тестов: $testFile');
    
    try {
      final result = await Process.run(
        'flutter',
        ['test', testFile],
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode == 0) {
        print('✅ Тесты прошли успешно: $testFile');
        passedTests++;
      } else {
        print('❌ Тесты не прошли: $testFile');
        print('Ошибка: ${result.stderr}');
        failedTests++;
      }
      
      totalTests++;
    } catch (e) {
      print('❌ Ошибка при запуске тестов: $testFile');
      print('Ошибка: $e');
      failedTests++;
      totalTests++;
    }
    
    print('');
  }

  // Итоговый отчет
  print('📊 ИТОГОВЫЙ ОТЧЕТ:');
  print('==================');
  print('✅ Прошло тестов: $passedTests');
  print('❌ Не прошло тестов: $failedTests');
  print('📋 Всего тестов: $totalTests');
  
  if (failedTests == 0) {
    print('🎉 Все тесты прошли успешно!');
  } else {
    print('⚠️  Некоторые тесты не прошли. Проверьте ошибки выше.');
  }
}
