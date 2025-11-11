# Краткая сводка диагностики — V6.DIAG-AUTO-REPORT

**Дата:** 2025-11-11  
**Версия:** 6.3.0+45  
**Последний рабочий релиз:** v6.0-ultimate (fdc839ae)

---

## Причина

**КРИТИЧЕСКАЯ ПРОБЛЕМА:** Дубликат зависимости `google_sign_in: ^6.2.1` в `pubspec.yaml` (строки 25 и 53) блокирует выполнение `flutter pub get` и сборку проекта.

**Вторичные проблемы:**
- Упрощение инициализации Firebase в `main.dart` (таймаут 8 сек вместо 10, удалена проверка `Firebase.app()`)
- Устройство 34HDU20228002261 offline (логи недоступны)

---

## Что правим

### 1. Удалить дубликат google_sign_in (КРИТИЧНО)
**Файл:** `pubspec.yaml`  
**Действие:** Удалить строку 53 с `google_sign_in: ^6.2.1`, оставить только строку 25

### 2. Восстановить проверку Firebase инициализации
**Файл:** `lib/main.dart`  
**Действие:** Добавить проверку `Firebase.app()` перед инициализацией (как в v6.0-ultimate)

### 3. Опционально: Увеличить таймаут до 10 сек
**Файл:** `lib/main.dart`  
**Действие:** Если шаг 2 не помогает, увеличить таймаут Firebase инициализации до 10 секунд

---

## Как проверяем

1. **Сборка:**
   ```bash
   flutter pub get  # должен выполниться без ошибок
   flutter build apk --release --no-tree-shake-icons
   ```

2. **Запуск:**
   - Приложение запускается без белого/чёрного экрана
   - Логи содержат `SPLASH:init-done`
   - `firebaseReady = true`

3. **Google Sign-In:**
   - Кнопка "Войти через Google" работает
   - Логи содержат `GOOGLE_SIGNIN_SUCCESS`
   - Нет ошибок `DEVELOPER_ERROR` или `unknown`

---

## Риски

1. **Низкий риск:** Исправление дубликата `google_sign_in` — безопасная операция
2. **Средний риск:** Изменения в `main.dart` могут повлиять на инициализацию, но изменения минимальны
3. **Высокий риск:** Если SHA-1 сертификат не совпадает → Google Sign-In не будет работать (требуется проверка на Firebase Console)

---

## Откат (если не поможет)

```bash
git checkout fdc839ae
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

---

**Полный отчёт:** `diagnostics/diag_full_report.md`  
**Git diff:** `diagnostics/git_diff_working_vs_current.patch`  
**Git история:** `diagnostics/git_history.txt`

