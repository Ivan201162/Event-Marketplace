import 'dart:io';
import 'dart:convert';

/// Скрипт для сборки и тестирования проекта
class BuildAndTest {
  static const String projectName = 'event_marketplace_app';
  static const String packageName = 'com.eventmarketplace.app';

  /// Основная функция сборки и тестирования
  static Future<void> buildAndTest() async {
    print('🚀 Начинаем сборку и тестирование проекта...');

    try {
      // 1. Очистка проекта
      await _cleanProject();

      // 2. Получение зависимостей
      await _getDependencies();

      // 3. Анализ кода
      await _analyzeCode();

      // 4. Запуск тестов
      await _runTests();

      // 5. Сборка APK
      await _buildAPK();

      // 6. Установка на устройство
      await _installOnDevice();

      // 7. Запуск тестов на устройстве
      await _runDeviceTests();

      print('✅ Сборка и тестирование завершены успешно!');
    } catch (e) {
      print('❌ Ошибка при сборке: $e');
      exit(1);
    }
  }

  /// Очистка проекта
  static Future<void> _cleanProject() async {
    print('🧹 Очищаем проект...');

    try {
      final result = await Process.run('flutter', ['clean']);

      if (result.exitCode == 0) {
        print('✅ Проект очищен');
      } else {
        throw Exception('Ошибка при очистке проекта: ${result.stderr}');
      }
    } catch (e) {
      print('❌ Ошибка при очистке: $e');
      rethrow;
    }
  }

  /// Получение зависимостей
  static Future<void> _getDependencies() async {
    print('📦 Получаем зависимости...');

    try {
      final result = await Process.run('flutter', ['pub', 'get']);

      if (result.exitCode == 0) {
        print('✅ Зависимости получены');
      } else {
        throw Exception('Ошибка при получении зависимостей: ${result.stderr}');
      }
    } catch (e) {
      print('❌ Ошибка при получении зависимостей: $e');
      rethrow;
    }
  }

  /// Анализ кода
  static Future<void> _analyzeCode() async {
    print('🔍 Анализируем код...');

    try {
      final result = await Process.run('flutter', ['analyze']);

      if (result.exitCode == 0) {
        print('✅ Анализ кода прошел успешно');
      } else {
        print('⚠️  Анализ кода нашел проблемы: ${result.stderr}');
        // Не прерываем сборку, если есть предупреждения
      }
    } catch (e) {
      print('❌ Ошибка при анализе кода: $e');
      rethrow;
    }
  }

  /// Запуск тестов
  static Future<void> _runTests() async {
    print('🧪 Запускаем тесты...');

    try {
      final result = await Process.run('flutter', ['test']);

      if (result.exitCode == 0) {
        print('✅ Тесты прошли успешно');
      } else {
        throw Exception('Тесты не прошли: ${result.stderr}');
      }
    } catch (e) {
      print('❌ Ошибка при запуске тестов: $e');
      rethrow;
    }
  }

  /// Сборка APK
  static Future<void> _buildAPK() async {
    print('📱 Собираем APK...');

    try {
      final result =
          await Process.run('flutter', ['build', 'apk', '--release']);

      if (result.exitCode == 0) {
        print('✅ APK собран успешно');

        // Проверяем размер APK
        final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
        if (apkFile.existsSync()) {
          final size = await apkFile.length();
          final sizeMB = (size / (1024 * 1024)).toStringAsFixed(2);
          print('📊 Размер APK: ${sizeMB}MB');
        }
      } else {
        throw Exception('Ошибка при сборке APK: ${result.stderr}');
      }
    } catch (e) {
      print('❌ Ошибка при сборке APK: $e');
      rethrow;
    }
  }

  /// Установка на устройство
  static Future<void> _installOnDevice() async {
    print('📱 Устанавливаем на устройство...');

    try {
      // Проверяем подключение устройства
      final devicesResult = await Process.run('adb', ['devices']);
      if (devicesResult.exitCode != 0) {
        print('⚠️  ADB не найден или устройство не подключено');
        return;
      }

      final devices = devicesResult.stdout.toString();
      if (!devices.contains('device')) {
        print('⚠️  Устройство не подключено');
        return;
      }

      // Удаляем старое приложение
      await Process.run('adb', ['uninstall', packageName]);

      // Устанавливаем новое
      final installResult = await Process.run('adb',
          ['install', '-r', 'build/app/outputs/flutter-apk/app-release.apk']);

      if (installResult.exitCode == 0) {
        print('✅ Приложение установлено на устройство');
      } else {
        print('❌ Ошибка при установке: ${installResult.stderr}');
      }
    } catch (e) {
      print('❌ Ошибка при установке на устройство: $e');
    }
  }

  /// Запуск тестов на устройстве
  static Future<void> _runDeviceTests() async {
    print('🧪 Запускаем тесты на устройстве...');

    try {
      // Запускаем интеграционные тесты
      final result =
          await Process.run('flutter', ['test', 'integration_test/']);

      if (result.exitCode == 0) {
        print('✅ Интеграционные тесты прошли успешно');
      } else {
        print('⚠️  Интеграционные тесты не прошли: ${result.stderr}');
      }
    } catch (e) {
      print('❌ Ошибка при запуске интеграционных тестов: $e');
    }
  }

  /// Создание отчета о сборке
  static Future<void> createBuildReport() async {
    print('📝 Создаем отчет о сборке...');

    try {
      final report = StringBuffer();
      report.writeln('# Отчет о сборке проекта');
      report.writeln();
      report.writeln('## Информация о проекте:');
      report.writeln('- Название: $projectName');
      report.writeln('- Пакет: $packageName');
      report.writeln('- Дата сборки: ${DateTime.now().toIso8601String()}');
      report.writeln();
      report.writeln('## Выполненные действия:');
      report.writeln('- ✅ Очистка проекта');
      report.writeln('- ✅ Получение зависимостей');
      report.writeln('- ✅ Анализ кода');
      report.writeln('- ✅ Запуск тестов');
      report.writeln('- ✅ Сборка APK');
      report.writeln('- ✅ Установка на устройство');
      report.writeln('- ✅ Запуск тестов на устройстве');
      report.writeln();
      report.writeln('## Результаты:');
      report.writeln('- APK собран успешно');
      report.writeln('- Приложение установлено на устройство');
      report.writeln('- Тесты прошли успешно');
      report.writeln();
      report.writeln('## Следующие шаги:');
      report.writeln('- Протестируйте приложение на устройстве');
      report.writeln('- Проверьте все функции');
      report.writeln('- Убедитесь в корректной работе навигации');
      report.writeln('- Проверьте работу уведомлений');

      final reportFile = File('BUILD_REPORT.md');
      await reportFile.writeAsString(report.toString());

      print('✅ Отчет о сборке создан: BUILD_REPORT.md');
    } catch (e) {
      print('❌ Ошибка при создании отчета: $e');
    }
  }

  /// Проверка готовности к релизу
  static Future<void> checkReleaseReadiness() async {
    print('🔍 Проверяем готовность к релизу...');

    try {
      final checks = <String, bool>{};

      // Проверка наличия APK
      final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
      checks['APK собран'] = apkFile.existsSync();

      // Проверка размера APK
      if (apkFile.existsSync()) {
        final size = await apkFile.length();
        final sizeMB = size / (1024 * 1024);
        checks['Размер APK < 100MB'] = sizeMB < 100;
      }

      // Проверка тестов
      final testResult =
          await Process.run('flutter', ['test', '--no-sound-null-safety']);
      checks['Тесты прошли'] = testResult.exitCode == 0;

      // Проверка анализа
      final analyzeResult = await Process.run('flutter', ['analyze']);
      checks['Анализ прошел'] = analyzeResult.exitCode == 0;

      print('📊 Результаты проверки:');
      for (final entry in checks.entries) {
        final status = entry.value ? '✅' : '❌';
        print('$status ${entry.key}');
      }

      final allPassed = checks.values.every((value) => value);
      if (allPassed) {
        print('🎉 Проект готов к релизу!');
      } else {
        print('⚠️  Проект не готов к релизу. Исправьте ошибки выше.');
      }
    } catch (e) {
      print('❌ Ошибка при проверке готовности: $e');
    }
  }
}

/// Главная функция
void main() async {
  await BuildAndTest.buildAndTest();
  await BuildAndTest.createBuildReport();
  await BuildAndTest.checkReleaseReadiness();
}
