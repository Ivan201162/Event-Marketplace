# Базовый анализ проекта Event Marketplace App

## Информация о среде
- **Flutter**: 3.35.3 (stable)
- **Dart**: 3.9.2
- **Ветка**: main

## Статистика ошибок
**Всего найдено: 7373 проблемы**

### Критические ошибки (error): ~20
1. **argument_type_not_assignable** - несоответствие типов String? и String
2. **undefined_method** - отсутствующие методы `_getCategoryColor`, `_getCategoryIcon`, `withOpacity`
3. **non_exhaustive_switch_statement** - неполные switch выражения

### Предупреждения (warning): ~50
1. **inference_failure_on_function_invocation** - проблемы с выводом типов
2. **unused_local_variable** - неиспользуемые переменные
3. **dead_null_aware_expression** - мертвый код

### Информационные сообщения (info): ~7300
1. **deprecated_member_use** - использование устаревших API (withOpacity, textScaleFactor, VideoPlayerController.network)
2. **flutter_style_todos** - неправильный формат TODO комментариев
3. **directives_ordering** - неправильный порядок импортов
4. **prefer_expression_function_bodies** - предпочтение выражений вместо блоков

## Топ-20 повторяющихся проблем

1. **withOpacity deprecated** - 200+ случаев
2. **flutter_style_todos** - 150+ случаев  
3. **directives_ordering** - 100+ случаев
4. **prefer_expression_function_bodies** - 80+ случаев
5. **avoid_catches_without_on_clauses** - 60+ случаев
6. **always_put_control_body_on_new_line** - 50+ случаев
7. **inference_failure_on_function_invocation** - 40+ случаев
8. **unused_local_variable** - 30+ случаев
9. **textScaleFactor deprecated** - 25+ случаев
10. **VideoPlayerController.network deprecated** - 20+ случаев

## Приоритеты исправления

### Высокий приоритет (блокируют компиляцию)
- undefined_method в guest_widget.dart и idea_widget.dart
- argument_type_not_assignable
- non_exhaustive_switch_statement

### Средний приоритет (влияют на функциональность)
- inference_failure_on_function_invocation
- unused_local_variable
- dead_null_aware_expression

### Низкий приоритет (стиль кода)
- deprecated_member_use
- flutter_style_todos
- directives_ordering
