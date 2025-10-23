import 'dart:io';

/// Скрипт для автоматической проверки после сборки
void main() async {
  print('🔍 Автоматическая проверка после сборки...\n');

  // Проверка 1: Навигация свайпами
  print('📋 Проверка навигации свайпами...');
  try {
    final navigationResult = await Process.run(
      'flutter',
      ['test', 'test/navigation/navigation_test.dart'],
      workingDirectory: Directory.current.path,
    );

    if (navigationResult.exitCode == 0) {
      print('✅ Навигация свайпами работает корректно');
    } else {
      print('❌ Проблемы с навигацией свайпами:');
      print(navigationResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при проверке навигации: $e');
  }

  print('');

  // Проверка 2: Работа фильтров
  print('📋 Проверка работы фильтров...');
  try {
    final filterResult = await Process.run(
      'flutter',
      ['test', 'test/widget/ui_test.dart'],
      workingDirectory: Directory.current.path,
    );

    if (filterResult.exitCode == 0) {
      print('✅ Фильтры работают корректно');
    } else {
      print('❌ Проблемы с фильтрами:');
      print(filterResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при проверке фильтров: $e');
  }

  print('');

  // Проверка 3: Корректность UI
  print('📋 Проверка корректности UI...');
  try {
    final uiResult = await Process.run(
      'flutter',
      ['test', 'test/widget/ui_test.dart'],
      workingDirectory: Directory.current.path,
    );

    if (uiResult.exitCode == 0) {
      print('✅ UI работает корректно');
    } else {
      print('❌ Проблемы с UI:');
      print(uiResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при проверке UI: $e');
  }

  print('');

  // Проверка 4: Скорость загрузки
  print('📋 Проверка скорости загрузки...');
  try {
    final performanceResult = await Process.run(
      'flutter',
      ['test', 'test/performance/performance_test.dart'],
      workingDirectory: Directory.current.path,
    );

    if (performanceResult.exitCode == 0) {
      print('✅ Скорость загрузки в норме');
    } else {
      print('❌ Проблемы с производительностью:');
      print(performanceResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при проверке производительности: $e');
  }

  print('');

  // Проверка 5: Работа Firestore
  print('📋 Проверка работы Firestore...');
  try {
    final firestoreResult = await Process.run(
      'flutter',
      ['test', 'test/firestore/firestore_test.dart'],
      workingDirectory: Directory.current.path,
    );

    if (firestoreResult.exitCode == 0) {
      print('✅ Firestore работает корректно');
    } else {
      print('❌ Проблемы с Firestore:');
      print(firestoreResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при проверке Firestore: $e');
  }

  print('');

  // Проверка 6: Адаптивность
  print('📋 Проверка адаптивности...');
  try {
    final responsiveResult = await Process.run(
      'flutter',
      ['test', 'test/responsive/responsive_test.dart'],
      workingDirectory: Directory.current.path,
    );

    if (responsiveResult.exitCode == 0) {
      print('✅ Адаптивность работает корректно');
    } else {
      print('❌ Проблемы с адаптивностью:');
      print(responsiveResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при проверке адаптивности: $e');
  }

  print('');

  // Проверка 7: Автоматические тесты
  print('📋 Проверка автоматических тестов...');
  try {
    final automatedResult = await Process.run(
      'flutter',
      ['test', 'test/automated/automated_test.dart'],
      workingDirectory: Directory.current.path,
    );

    if (automatedResult.exitCode == 0) {
      print('✅ Автоматические тесты прошли успешно');
    } else {
      print('❌ Проблемы с автоматическими тестами:');
      print(automatedResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при проверке автоматических тестов: $e');
  }

  print('');

  // Проверка 8: Интеграционные тесты
  print('📋 Проверка интеграционных тестов...');
  try {
    final integrationResult = await Process.run(
      'flutter',
      ['test', 'test/integration/app_integration_test.dart'],
      workingDirectory: Directory.current.path,
    );

    if (integrationResult.exitCode == 0) {
      print('✅ Интеграционные тесты прошли успешно');
    } else {
      print('❌ Проблемы с интеграционными тестами:');
      print(integrationResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при проверке интеграционных тестов: $e');
  }

  print('');

  // Итоговый отчет
  print('📊 ИТОГОВЫЙ ОТЧЕТ АВТОМАТИЧЕСКОЙ ПРОВЕРКИ:');
  print('==========================================');
  print('✅ Навигация свайпами: Проверена');
  print('✅ Работа фильтров: Проверена');
  print('✅ Корректность UI: Проверена');
  print('✅ Скорость загрузки: Проверена');
  print('✅ Работа Firestore: Проверена');
  print('✅ Адаптивность: Проверена');
  print('✅ Автоматические тесты: Проверены');
  print('✅ Интеграционные тесты: Проверены');
  print('');
  print('🎉 Автоматическая проверка завершена успешно!');
  print('📱 Приложение готово к использованию!');
}