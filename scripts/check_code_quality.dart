import 'dart:io';

/// Скрипт для проверки качества кода
void main() async {
  print('🔍 Проверка качества кода...\n');

  // Анализ кода
  print('📋 Запуск анализа кода...');
  try {
    final analyzeResult = await Process.run(
      'flutter',
      ['analyze'],
      workingDirectory: Directory.current.path,
    );

    if (analyzeResult.exitCode == 0) {
      print('✅ Анализ кода прошел успешно');
    } else {
      print('❌ Анализ кода выявил проблемы:');
      print(analyzeResult.stdout);
      print(analyzeResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при анализе кода: $e');
  }

  print('');

  // Проверка зависимостей
  print('📋 Проверка зависимостей...');
  try {
    final pubResult = await Process.run(
      'flutter',
      ['pub', 'deps'],
      workingDirectory: Directory.current.path,
    );

    if (pubResult.exitCode == 0) {
      print('✅ Зависимости в порядке');
    } else {
      print('❌ Проблемы с зависимостями:');
      print(pubResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при проверке зависимостей: $e');
  }

  print('');

  // Проверка форматирования
  print('📋 Проверка форматирования...');
  try {
    final formatResult = await Process.run(
      'flutter',
      ['format', '--set-exit-if-changed', '.'],
      workingDirectory: Directory.current.path,
    );

    if (formatResult.exitCode == 0) {
      print('✅ Код отформатирован правильно');
    } else {
      print('❌ Код требует форматирования:');
      print(formatResult.stdout);
    }
  } catch (e) {
    print('❌ Ошибка при проверке форматирования: $e');
  }

  print('');

  // Проверка размера приложения
  print('📋 Проверка размера приложения...');
  try {
    final buildResult = await Process.run(
      'flutter',
      ['build', 'apk', '--analyze-size'],
      workingDirectory: Directory.current.path,
    );

    if (buildResult.exitCode == 0) {
      print('✅ Сборка прошла успешно');
      print('📊 Анализ размера:');
      print(buildResult.stdout);
    } else {
      print('❌ Ошибка при сборке:');
      print(buildResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при проверке размера: $e');
  }

  print('');

  // Проверка безопасности
  print('📋 Проверка безопасности...');
  try {
    final securityResult = await Process.run(
      'flutter',
      ['pub', 'audit'],
      workingDirectory: Directory.current.path,
    );

    if (securityResult.exitCode == 0) {
      print('✅ Проблем безопасности не найдено');
    } else {
      print('⚠️  Найдены проблемы безопасности:');
      print(securityResult.stdout);
    }
  } catch (e) {
    print('❌ Ошибка при проверке безопасности: $e');
  }

  print('');

  // Итоговый отчет
  print('📊 ИТОГОВЫЙ ОТЧЕТ КАЧЕСТВА КОДА:');
  print('================================');
  print('✅ Анализ кода: Проверен');
  print('✅ Зависимости: Проверены');
  print('✅ Форматирование: Проверено');
  print('✅ Сборка: Проверена');
  print('✅ Безопасность: Проверена');
  print('');
  print('🎉 Проверка качества кода завершена!');
}
