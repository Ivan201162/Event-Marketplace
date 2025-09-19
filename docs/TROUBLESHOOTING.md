# Troubleshooting Guide

## Общие проблемы

### Проблемы с компиляцией

#### Ошибки типов и несовместимости
**Проблема**: Множественные ошибки компиляции типа "The argument type 'X' can't be assigned to the parameter type 'Y'"

**Решение**:
1. Проверьте версии зависимостей в `pubspec.yaml`
2. Выполните `flutter clean && flutter pub get`
3. Проверьте совместимость версий Flutter и Dart
4. Обновите импорты и типы данных

#### Ошибки с Firebase
**Проблема**: "Firebase not initialized" или ошибки конфигурации

**Решение**:
1. Убедитесь, что файлы конфигурации Firebase присутствуют:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
2. Выполните `flutterfire configure`
3. Проверьте правильность настройки Firebase в `firebase_options.dart`

### Проблемы с NDK (Android)

#### NDK не найден
**Проблема**: "NDK at path did not have a source.properties file"

**Решение**:
1. Установите Android NDK через Android Studio SDK Manager
2. Или отключите NDK в `android/gradle.properties`:
   ```
   android.useDeprecatedNdk=false
   ```
3. См. подробности в `audit/NDK_ISSUE_LOG.md`

### Проблемы с Windows сборкой

#### Ошибки компиляции Windows
**Проблема**: Windows сборка не удается из-за ошибок компиляции

**Решение**:
1. Установите Visual Studio с C++ workload
2. Установите Windows 10 SDK
3. Проверьте переменные окружения
4. См. подробности в `audit/WINDOWS_BUILD.md`

### Проблемы с зависимостями

#### Конфликты версий
**Проблема**: "Version solving failed"

**Решение**:
1. Проверьте совместимость версий в `pubspec.yaml`
2. Выполните `flutter pub deps` для анализа зависимостей
3. Обновите зависимости: `flutter pub upgrade`
4. При необходимости зафиксируйте версии

#### Устаревшие пакеты
**Проблема**: Предупреждения о deprecated методах

**Решение**:
1. Выполните `flutter pub outdated` для проверки
2. Обновите пакеты до совместимых версий
3. Замените deprecated методы на новые

### Проблемы с секретами

#### Секретные файлы в Git
**Проблема**: Секретные файлы попали в репозиторий

**Решение**:
1. Удалите файлы из Git: `git rm --cached <file>`
2. Добавьте правила в `.gitignore`
3. Используйте переменные окружения или CI secrets
4. См. подробности в `audit/SECRETS_AUDIT.md`

### Проблемы с тестами

#### Тесты не проходят
**Проблема**: "Some tests failed" или ошибки компиляции в тестах

**Решение**:
1. Исправьте ошибки компиляции в основном коде
2. Обновите тесты под новые API
3. Проверьте моки и тестовые данные
4. Выполните `flutter test --reporter expanded` для подробного вывода

### Проблемы с производительностью

#### Медленная загрузка изображений
**Проблема**: Изображения загружаются медленно

**Решение**:
1. Используйте `CachedNetworkImage` вместо `Image.network`
2. Настройте кэширование
3. Оптимизируйте размеры изображений
4. Используйте lazy loading для списков

#### Проблемы с памятью
**Проблема**: Утечки памяти или высокое потребление

**Решение**:
1. Используйте `const` конструкторы где возможно
2. Замените длинные списки на `ListView.builder`
3. Правильно dispose контроллеры и стримы
4. Используйте профилирование для выявления проблем

## Полезные команды

### Отладка
```bash
# Проверка окружения
flutter doctor -v

# Анализ кода
flutter analyze

# Форматирование
dart format .

# Очистка и пересборка
flutter clean
flutter pub get
flutter build apk --debug
```

### Тестирование
```bash
# Запуск тестов
flutter test

# Запуск с подробным выводом
flutter test --reporter expanded

# Запуск конкретного теста
flutter test test/widget_test.dart
```

### Сборка
```bash
# Android debug
flutter build apk --debug

# Android release
flutter build apk --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

## Получение помощи

1. Проверьте этот файл и документацию
2. Поищите в Issues репозитория
3. Создайте новый Issue с подробным описанием проблемы
4. Приложите логи и информацию об окружении

## Полезные ссылки

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
