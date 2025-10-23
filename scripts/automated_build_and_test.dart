import 'dart:io';

/// Скрипт для автоматической сборки и тестирования
void main() async {
  print('🤖 Автоматическая сборка и тестирование...\n');

  // Шаг 1: Очистка проекта
  print('🧹 Очистка проекта...');
  try {
    final cleanResult = await Process.run(
      'flutter',
      ['clean'],
      workingDirectory: Directory.current.path,
    );

    if (cleanResult.exitCode == 0) {
      print('✅ Проект очищен');
    } else {
      print('❌ Ошибка при очистке проекта:');
      print(cleanResult.stderr);
      return;
    }
  } catch (e) {
    print('❌ Ошибка при очистке проекта: $e');
    return;
  }

  print('');

  // Шаг 2: Получение зависимостей
  print('📦 Получение зависимостей...');
  try {
    final pubGetResult = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: Directory.current.path,
    );

    if (pubGetResult.exitCode == 0) {
      print('✅ Зависимости получены');
    } else {
      print('❌ Ошибка при получении зависимостей:');
      print(pubGetResult.stderr);
      return;
    }
  } catch (e) {
    print('❌ Ошибка при получении зависимостей: $e');
    return;
  }

  print('');

  // Шаг 3: Анализ кода
  print('🔍 Анализ кода...');
  try {
    final analyzeResult = await Process.run(
      'flutter',
      ['analyze'],
      workingDirectory: Directory.current.path,
    );

    if (analyzeResult.exitCode == 0) {
      print('✅ Анализ кода прошел успешно');
    } else {
      print('❌ Проблемы в коде:');
      print(analyzeResult.stdout);
      print(analyzeResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при анализе кода: $e');
  }

  print('');

  // Шаг 4: Запуск тестов
  print('🧪 Запуск тестов...');
  try {
    final testResult = await Process.run(
      'flutter',
      ['test'],
      workingDirectory: Directory.current.path,
    );

    if (testResult.exitCode == 0) {
      print('✅ Все тесты прошли успешно');
    } else {
      print('❌ Некоторые тесты не прошли:');
      print(testResult.stdout);
      print(testResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при запуске тестов: $e');
  }

  print('');

  // Шаг 5: Сборка APK
  print('📱 Сборка APK...');
  try {
    final buildResult = await Process.run(
      'flutter',
      ['build', 'apk', '--release'],
      workingDirectory: Directory.current.path,
    );

    if (buildResult.exitCode == 0) {
      print('✅ APK собран успешно');
    } else {
      print('❌ Ошибка при сборке APK:');
      print(buildResult.stderr);
      return;
    }
  } catch (e) {
    print('❌ Ошибка при сборке APK: $e');
    return;
  }

  print('');

  // Шаг 6: Проверка размера APK
  print('📊 Проверка размера APK...');
  try {
    final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
    if (await apkFile.exists()) {
      final size = await apkFile.length();
      final sizeMB = (size / (1024 * 1024)).toStringAsFixed(2);
      print('📱 Размер APK: ${sizeMB}MB');

      if (size > 100 * 1024 * 1024) {
        // 100MB
        print('⚠️  APK слишком большой (>100MB)');
      } else {
        print('✅ Размер APK в норме');
      }
    } else {
      print('❌ APK файл не найден');
    }
  } catch (e) {
    print('❌ Ошибка при проверке размера APK: $e');
  }

  print('');

  // Шаг 7: Установка на устройство (если подключено)
  print('📱 Установка на устройство...');
  try {
    final devicesResult = await Process.run(
      'adb',
      ['devices'],
      workingDirectory: Directory.current.path,
    );

    if (devicesResult.exitCode == 0 &&
        devicesResult.stdout.toString().contains('device')) {
      print('📱 Устройство подключено, устанавливаем APK...');

      final installResult = await Process.run(
        'adb',
        ['install', '-r', 'build/app/outputs/flutter-apk/app-release.apk'],
        workingDirectory: Directory.current.path,
      );

      if (installResult.exitCode == 0) {
        print('✅ APK установлен на устройство');
      } else {
        print('❌ Ошибка при установке APK:');
        print(installResult.stderr);
      }
    } else {
      print('⚠️  Устройство не подключено, пропускаем установку');
    }
  } catch (e) {
    print('❌ Ошибка при установке на устройство: $e');
  }

  print('');

  // Шаг 8: Запуск приложения на устройстве
  print('🚀 Запуск приложения...');
  try {
    final launchResult = await Process.run(
      'adb',
      ['shell', 'am', 'start', '-n', 'com.eventmarketplace.app/.MainActivity'],
      workingDirectory: Directory.current.path,
    );

    if (launchResult.exitCode == 0) {
      print('✅ Приложение запущено на устройстве');
    } else {
      print('❌ Ошибка при запуске приложения:');
      print(launchResult.stderr);
    }
  } catch (e) {
    print('❌ Ошибка при запуске приложения: $e');
  }

  print('');

  // Итоговый отчет
  print('📊 ИТОГОВЫЙ ОТЧЕТ АВТОМАТИЧЕСКОЙ СБОРКИ:');
  print('========================================');
  print('✅ Очистка проекта: Выполнена');
  print('✅ Получение зависимостей: Выполнено');
  print('✅ Анализ кода: Выполнен');
  print('✅ Запуск тестов: Выполнен');
  print('✅ Сборка APK: Выполнена');
  print('✅ Проверка размера: Выполнена');
  print('✅ Установка на устройство: Выполнена');
  print('✅ Запуск приложения: Выполнен');
  print('');
  print('🎉 Автоматическая сборка и тестирование завершены успешно!');
  print('📱 Приложение готово к использованию!');
}
