# CI/CD Pipeline для Event Marketplace App

## Обзор

Проект настроен с полным CI/CD pipeline для автоматического тестирования, сборки и развертывания.

## Workflows

### 1. CI Pipeline (`.github/workflows/ci.yml`)

**Триггеры:**
- Push в ветки `main` и `develop`
- Pull Request в ветки `main` и `develop`

**Задачи:**
- **Test**: Запуск тестов, анализ кода, проверка форматирования
- **Build Web**: Сборка веб-версии приложения
- **Build Android**: Сборка Android APK
- **Build Windows**: Сборка Windows приложения
- **Security Scan**: Сканирование уязвимостей с помощью Trivy

### 2. Release Pipeline (`.github/workflows/release.yml`)

**Триггеры:**
- Push тегов с версией (например, `v1.0.0`)

**Задачи:**
- Сборка всех платформ
- Создание GitHub Release с артефактами

### 3. CodeQL Analysis (`.github/workflows/codeql.yml`)

**Триггеры:**
- Push в ветки `main` и `develop`
- Pull Request в ветки `main` и `develop`
- Еженедельно по воскресеньям

**Задачи:**
- Анализ безопасности кода
- Поиск уязвимостей и проблем безопасности

### 4. Auto Format (`.github/workflows/format.yml`)

**Триггеры:**
- Pull Request в ветки `main` и `develop`

**Задачи:**
- Автоматическое форматирование кода
- Коммит отформатированного кода

## Конфигурации

### Dependabot (`.github/dependabot.yml`)

Автоматическое обновление зависимостей:
- **npm**: Еженедельно по понедельникам
- **pub**: Еженедельно по понедельникам  
- **GitHub Actions**: Еженедельно по понедельникам

### Codecov (`codecov.yml`)

Настройки покрытия кода:
- Целевое покрытие: 80%
- Порог изменения: 5%

## Использование

### Создание релиза

1. Создайте тег с версией:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. GitHub Actions автоматически создаст релиз с артефактами

### Проверка качества кода

Все Pull Request автоматически проверяются на:
- Форматирование кода
- Анализ статического кода
- Покрытие тестами
- Безопасность

### Мониторинг

- **GitHub Actions**: Просмотр статуса сборок
- **Codecov**: Отчеты о покрытии кода
- **GitHub Security**: Анализ уязвимостей
- **Dependabot**: Обновления зависимостей

## Требования

- Flutter 3.24.0+
- Dart 3.0+
- Java 17+ (для Android сборки)
- Node.js (для веб-сборки)

## Локальная разработка

### Запуск тестов
```bash
flutter test
```

### Анализ кода
```bash
flutter analyze
```

### Форматирование
```bash
dart format .
```

### Сборка
```bash
# Web
flutter build web --release

# Android
flutter build apk --release

# Windows
flutter build windows --release
```

## Troubleshooting

### Проблемы с Android сборкой
- Убедитесь, что `desugar_jdk_libs` версии 2.1.4+
- Проверьте настройки Java 17

### Проблемы с тестами
- Убедитесь, что все зависимости установлены
- Проверьте конфигурацию Firebase для тестов

### Проблемы с форматированием
- Запустите `dart format .` локально
- Проверьте настройки анализатора в `analysis_options.yaml`
