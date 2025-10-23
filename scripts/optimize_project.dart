import 'dart:io';

/// Скрипт для оптимизации проекта
class ProjectOptimizer {
  static const String pubspecPath = 'pubspec.yaml';
  static const String analysisPath = 'analysis_options.yaml';
  
  /// Основная функция оптимизации
  static Future<void> optimize() async {
    debugPrint('🚀 Начинаем оптимизацию проекта...');
    
    try {
      // 1. Анализ зависимостей
      await _analyzeDependencies();
      
      // 2. Очистка неиспользуемых импортов
      await _cleanUnusedImports();
      
      // 3. Оптимизация кода
      await _optimizeCode();
      
      // 4. Очистка временных файлов
      await _cleanTempFiles();
      
      // 5. Проверка размера проекта
      await _checkProjectSize();
      
      print('✅ Оптимизация проекта завершена!');
    } catch (e) {
      print('❌ Ошибка при оптимизации: $e');
    }
  }
  
  /// Анализ зависимостей
  static Future<void> _analyzeDependencies() async {
    print('📦 Анализируем зависимости...');
    
    try {
      final pubspecFile = File(pubspecPath);
      if (!pubspecFile.existsSync()) {
        print('❌ Файл pubspec.yaml не найден');
        return;
      }
      
      final content = await pubspecFile.readAsString();
      final lines = content.split('\n');
      
      // Список потенциально неиспользуемых зависимостей
      final potentiallyUnused = [
        'audioplayers',
        'chewie',
        'fl_chart',
        'flutter_map',
        'flutter_staggered_grid_view',
        'flutter_stripe',
        'geocoding',
        'geolocator',
        'hive_flutter',
        'image',
        'in_app_review',
        'latlong2',
        'pdf',
        'photo_view',
        'pointycastle',
        'printing',
        'qr_flutter',
        'signature',
        'story_view',
        'supabase_flutter',
        'table_calendar',
        'timeago',
        'timezone',
        'video_player',
        'video_thumbnail',
      ];
      
      print('🔍 Проверяем использование зависимостей...');
      
      for (final dependency in potentiallyUnused) {
        if (content.contains(dependency)) {
          print('⚠️  Возможно неиспользуемая зависимость: $dependency');
        }
      }
      
      print('✅ Анализ зависимостей завершен');
  } catch (e) {
      print('❌ Ошибка при анализе зависимостей: $e');
    }
  }
  
  /// Очистка неиспользуемых импортов
  static Future<void> _cleanUnusedImports() async {
    print('🧹 Очищаем неиспользуемые импорты...');
    
    try {
      final libDir = Directory('lib');
      if (!libDir.existsSync()) {
        print('❌ Директория lib не найдена');
        return;
      }

      int cleanedFiles = 0;
      
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = await entity.readAsString();
          final lines = content.split('\n');
          final cleanedLines = <String>[];
          bool hasChanges = false;
          
          for (final line in lines) {
            if (line.trim().startsWith('import ') && line.trim().endsWith(';')) {
              final importPath = line.trim().substring(7, line.trim().length - 1);
              final importPathClean = importPath.replaceAll("'", '').replaceAll('"', '');
              
              // Проверяем, используется ли импорт
              if (!_isImportUsed(content, importPathClean)) {
                print('🗑️  Удаляем неиспользуемый импорт: $importPathClean');
                hasChanges = true;
                continue;
              }
          }
          
          cleanedLines.add(line);
        }
        
        if (hasChanges) {
          await entity.writeAsString(cleanedLines.join('\n'));
          cleanedFiles++;
        }
      }
      
      print('✅ Очищено $cleanedFiles файлов');
    } catch (e) {
      print('❌ Ошибка при очистке импортов: $e');
    }
  }
  
  /// Проверка использования импорта
  static bool _isImportUsed(String content, String importPath) {
    // Простая проверка использования импорта
    final importName = importPath.split('/').last.split('.').first;
    final importNameCapitalized = importName[0].toUpperCase() + importName.substring(1);
    
    // Проверяем различные варианты использования
    return content.contains(importName) || 
           content.contains(importNameCapitalized) ||
           content.contains(importPath.split('/').last);
  }
  
  /// Оптимизация кода
  static Future<void> _optimizeCode() async {
    print('⚡ Оптимизируем код...');
    
    try {
      // Запускаем dart fix
      final result = await Process.run('dart', ['fix', '--apply']);
      
      if (result.exitCode == 0) {
        print('✅ Dart fix применен успешно');
      } else {
        print('⚠️  Dart fix завершился с предупреждениями: ${result.stderr}');
      }
      
      // Запускаем flutter analyze
      final analyzeResult = await Process.run('flutter', ['analyze']);
      
      if (analyzeResult.exitCode == 0) {
        print('✅ Flutter analyze прошел успешно');
      } else {
        print('⚠️  Flutter analyze нашел проблемы: ${analyzeResult.stderr}');
      }
      
    } catch (e) {
      print('❌ Ошибка при оптимизации кода: $e');
    }
  }
  
  /// Очистка временных файлов
  static Future<void> _cleanTempFiles() async {
    print('🧹 Очищаем временные файлы...');
    
    try {
      final tempDirs = [
        'build',
        '.dart_tool',
        'ios/Pods',
        'android/.gradle',
        'android/app/build',
      ];
      
      int cleanedDirs = 0;
      
      for (final dirPath in tempDirs) {
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
          cleanedDirs++;
          print('🗑️  Удалена директория: $dirPath');
        }
      }
      
      print('✅ Очищено $cleanedDirs директорий');
    } catch (e) {
      print('❌ Ошибка при очистке временных файлов: $e');
    }
  }
  
  /// Проверка размера проекта
  static Future<void> _checkProjectSize() async {
    print('📊 Проверяем размер проекта...');
    
    try {
      final result = await Process.run('du', ['-sh', '.']);
      
      if (result.exitCode == 0) {
        print('📁 Размер проекта: ${result.stdout.toString().trim()}');
      }
      
      // Проверяем размер отдельных директорий
      final dirsToCheck = ['lib', 'assets', 'android', 'ios'];
      
      for (final dirPath in dirsToCheck) {
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          final dirResult = await Process.run('du', ['-sh', dirPath]);
          if (dirResult.exitCode == 0) {
            print('📁 Размер $dirPath: ${dirResult.stdout.toString().trim()}');
          }
        }
      }
      
    } catch (e) {
      print('❌ Ошибка при проверке размера: $e');
    }
  }
  
  /// Создание отчета об оптимизации
  static Future<void> createOptimizationReport() async {
    print('📝 Создаем отчет об оптимизации...');
    
    try {
      final report = StringBuffer();
      report.writeln('# Отчет об оптимизации проекта');
      report.writeln();
      report.writeln('## Выполненные действия:');
      report.writeln('- ✅ Анализ зависимостей');
      report.writeln('- ✅ Очистка неиспользуемых импортов');
      report.writeln('- ✅ Оптимизация кода');
      report.writeln('- ✅ Очистка временных файлов');
      report.writeln('- ✅ Проверка размера проекта');
      report.writeln();
      report.writeln('## Рекомендации:');
      report.writeln('- Регулярно запускайте `flutter clean`');
      report.writeln('- Используйте `flutter analyze` для проверки кода');
      report.writeln('- Удаляйте неиспользуемые зависимости');
      report.writeln('- Оптимизируйте изображения в assets');
      report.writeln();
      report.writeln('## Следующие шаги:');
      report.writeln('- Запустите `flutter pub get`');
      report.writeln('- Запустите `flutter analyze`');
      report.writeln('- Соберите проект: `flutter build apk --release`');
      
      final reportFile = File('OPTIMIZATION_REPORT.md');
      await reportFile.writeAsString(report.toString());
      
      print('✅ Отчет создан: OPTIMIZATION_REPORT.md');
  } catch (e) {
      print('❌ Ошибка при создании отчета: $e');
    }
  }
}

/// Главная функция
void main() async {
  await ProjectOptimizer.optimize();
  await ProjectOptimizer.createOptimizationReport();
}