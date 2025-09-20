# Базовый снимок ошибок - Event Marketplace App

## Информация о среде
- **Flutter**: 3.35.3 (stable)
- **Dart**: 3.9.2 (stable)
- **Ветка Git**: main
- **Дата**: $(Get-Date)

## Текущее состояние анализатора
- **Всего проблем**: 7,829
- **Критические ошибки**: ~3,500+ (оценка)
- **Предупреждения**: ~2,000+ (оценка)
- **Информационные сообщения**: ~2,300+ (оценка)

## Основные категории ошибок

### 1. Критические ошибки компиляции
- `undefined_method` - неопределенные методы (ResponsiveCard, ResponsiveText, etc.)
- `undefined_class` - неопределенные классы (SecurityPasswordStrength, etc.)
- `missing_required_argument` - отсутствующие обязательные параметры
- `argument_type_not_assignable` - несовместимые типы аргументов
- `undefined_enum_constant` - неопределенные константы enum

### 2. Проблемы с UI компонентами
- ResponsiveCard/ResponsiveText не определены
- Неправильные параметры виджетов (isTitle, isSubtitle)
- Устаревшие методы (withOpacity, textScaleFactor)
- Неопределенные иконки (Icons.sessions, Icons.cleanup)

### 3. Проблемы с типами и null-safety
- `inference_failure_on_untyped_parameter` - неявные типы параметров
- `inference_failure_on_function_invocation` - неявные типы функций
- Проблемы с Future и async/await

### 4. Проблемы с тестами
- Отсутствующие параметры в тестах (prefs)
- Неопределенные функции в тестах (ResponsiveWidget, ResponsiveList)

### 5. Стилистические проблемы
- `flutter_style_todos` - неправильный формат TODO комментариев
- `deprecated_member_use` - использование устаревших методов
- `always_put_control_body_on_new_line` - форматирование кода

## План исправления
1. **Фаза 1**: Исправить критические ошибки компиляции
2. **Фаза 2**: Создать недостающие UI компоненты
3. **Фаза 3**: Исправить проблемы с типами
4. **Фаза 4**: Обновить тесты
5. **Фаза 5**: Исправить стилистические проблемы

## Цель
Достичь 0 критических ошибок и успешной сборки на всех платформах.
