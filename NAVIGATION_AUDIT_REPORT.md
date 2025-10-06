# Аудит навигации Event Marketplace App

**Дата:** 5 октября 2025  
**Система навигации:** go_router + PageView (BottomNavigation)

## 📋 Реестр экранов и навигации

### 🏗️ Архитектура навигации

**Основная структура:**
- **go_router** - основной роутер приложения
- **MainNavigationScreen** - корневой экран с PageView и BottomNavigation
- **6 основных вкладок** с собственными экранами

### 📱 Основные экраны (MainNavigationScreen)

| Вкладка | Экран | Класс | Обработка "Назад" | Статус |
|---------|-------|-------|-------------------|--------|
| 🏠 Главная | HomeScreen | `HomeScreen` | ❌ Нет AppBar | ⚠️ ПРОБЛЕМА |
| 🔍 Поиск | SearchScreen | `SearchScreen` | ✅ `Navigator.maybePop()` | ✅ ОК |
| 💬 Сообщения | ChatListScreen | `ChatListScreen` | ✅ `BackUtils.buildBackButton()` | ✅ ОК |
| 💡 Идеи | IdeasScreen | `IdeasScreen` | ✅ `context.canPop()` | ✅ ОК |
| 📅 Заказы | BookingsScreen | `BookingsScreenFull` | ✅ `BackUtils.buildBackButton()` | ✅ ОК |
| 👤 Профиль | ProfileScreen | `ProfileScreen` | ✅ `Navigator.maybePop()` | ✅ ОК |

### 🔍 Детальные экраны

#### ✅ Экраны с правильной обработкой "Назад"

| Экран | Класс | Метод | Статус |
|-------|-------|-------|--------|
| SpecialistProfileScreen | `SpecialistProfileScreen` | `context.pop()` | ✅ ОК |
| SpecialistProfileExtendedScreen | `SpecialistProfileExtendedScreen` | `context.pop()` | ✅ ОК |
| SpecialistProfileInstagramScreen | `SpecialistProfileInstagramScreen` | `context.pop()` | ✅ ОК |
| WriteReviewExtendedScreen | `WriteReviewExtendedScreen` | `context.pop()` | ✅ ОК |
| ChatListScreen | `ChatListScreen` | `BackUtils.buildBackButton()` | ✅ ОК |
| BookingsScreenFull | `BookingsScreenFull` | `BackUtils.buildBackButton()` | ✅ ОК |

#### ⚠️ Экраны с проблемами навигации

| Экран | Класс | Проблема | Статус |
|-------|-------|----------|--------|
| HomeScreen | `HomeScreen` | Нет AppBar, нет обработки "Назад" | ❌ КРИТИЧНО |
| IdeasScreen | `IdeasScreen` | Исправлен, но нужна проверка | ⚠️ ТРЕБУЕТ ПРОВЕРКИ |

#### 🔧 Экраны с устаревшими методами

| Экран | Класс | Текущий метод | Рекомендация |
|-------|-------|---------------|--------------|
| SearchScreen | `SearchScreen` | `Navigator.maybePop()` | Заменить на `BackNav.safeBack()` |
| ProfileScreen | `ProfileScreen` | `Navigator.maybePop()` | Заменить на `BackNav.safeBack()` |
| Множество диалогов | Различные | `Navigator.pop(context)` | Заменить на `context.pop()` |

### 🎯 Проблемы навигации

#### 1. ❌ КРИТИЧНО: HomeScreen без AppBar
- **Файл:** `lib/screens/main_navigation_screen.dart:175-198`
- **Проблема:** HomeScreen не имеет AppBar, нет обработки системной кнопки "Назад"
- **Решение:** Добавить AppBar с правильной обработкой "Назад"

#### 2. ⚠️ Смешанные методы навигации
- **Проблема:** Используются разные методы: `Navigator.pop()`, `context.pop()`, `Navigator.maybePop()`
- **Решение:** Унифицировать через `BackNav.safeBack()`

#### 3. ⚠️ Отсутствие корневого перехвата
- **Проблема:** Нет PopScope/WillPopScope на корневом уровне
- **Решение:** Добавить корневой перехват системной кнопки "Назад"

### 🏗️ Структура навигации

```
EventMarketplaceApp (go_router)
├── /auth → AuthScreen
├── /home → MainNavigationScreen (PageView)
│   ├── Tab 0: HomeScreen ❌
│   ├── Tab 1: SearchScreen ⚠️
│   ├── Tab 2: ChatListScreen ✅
│   ├── Tab 3: IdeasScreen ✅
│   ├── Tab 4: BookingsScreenFull ✅
│   └── Tab 5: ProfileScreen ⚠️
├── /profile/:userId → ProfileScreen
├── /specialist/:id → SpecialistProfileScreen
└── ... (другие детальные экраны)
```

### 📊 Статистика проблем

- **Всего экранов:** ~50+
- **С правильной навигацией:** ~30
- **С проблемами:** ~20
- **Критичные проблемы:** 1 (HomeScreen)
- **Требуют унификации:** ~15

### 🎯 План исправлений

1. **Создать BackNav утилиту** - унифицированная обработка "Назад"
2. **Исправить HomeScreen** - добавить AppBar и обработку "Назад"
3. **Добавить корневой перехват** - PopScope на MainNavigationScreen
4. **Унифицировать методы** - заменить все на BackNav.safeBack()
5. **Протестировать навигацию** - проверить все сценарии

### 🔧 Технические детали

**Используемые методы:**
- `context.pop()` - go_router (рекомендуется)
- `Navigator.pop(context)` - классический Navigator (устарел)
- `Navigator.maybePop()` - безопасный pop (устарел)
- `BackUtils.buildBackButton()` - кастомная утилита (частично)

**Рекомендуемый подход:**
- Создать `BackNav.safeBack()` для унификации
- Использовать PopScope для корневого перехвата
- Все экраны должны иметь AppBar с leading кнопкой




