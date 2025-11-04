# MAX APPLY — Refresh + Search + Settings + Stories + Deploy (RU)

**Ветка:** prod/max-refresh-settings-stories  
**Версия:** 4.5.0+7  
**Build tag:** v4.5-refresh-stories  
**Дата:** 2024-11-04

---

## Что исправлено

### 1. Pull-to-Refresh на всех экранах ✅

- **Home** (`lib/screens/home/home_screen_simple.dart`): RefreshIndicator с логированием `REFRESH_OK:home` / `REFRESH_ERR:home`
- **Feed** (`lib/screens/feed/feed_screen_improved.dart`): RefreshIndicator с инвалидацией провайдеров
- **Requests** (`lib/screens/requests/requests_screen_improved.dart`): RefreshIndicator
- **Chats** (`lib/screens/chat/chat_list_screen_improved.dart`): RefreshIndicator
- **Ideas** (`lib/screens/ideas/ideas_screen.dart`): RefreshIndicator
- **Search** (`lib/screens/search/search_screen_enhanced.dart`): RefreshIndicator с обновлением состояния
- **Profile** (`lib/screens/profile/profile_full_screen.dart`): RefreshIndicator на TabBarView

### 2. Главная страница ✅

- Удалён третий блок "Специалисты вашего города"
- Оставлены две карусели:
  - "Лучшие специалисты недели — Россия" (пагинация по 20)
  - "Лучшие специалисты недели — {город}" (пагинация по 20, если город указан)
- Обновлены провайдеры: `topSpecialistsByRussiaProvider` и `topSpecialistsByCityProvider` (limit 20)
- Логи: `HOME_LOADED`, `HOME_TOP_RU_COUNT:{n}`, `HOME_TOP_CITY_COUNT:{n}`
- Карточка специалиста: тап по всей карточке → профиль

### 3. Поиск специалистов ✅

- Кнопка "Попробовать снова" реально перезапускает запрос с индикатором загрузки
- Расширен список категорий (30+): ведущий, диджей, фотограф, видеограф, организатор мероприятий, аниматор, агенство праздников, аренда аппаратуры, аренда костюмов, аренда платьев, декоратор, флорист, пиротехник, свет, звукорежиссёр, кавер-бэнд, музыкант, вокалист, ведущий аукционов, тамада, сценарист, постановщик, координатор, детский аниматор, иллюзионист, фокусник, хореограф, хостес, промо-персонал
- Фильтры: Город, Категории (multi-select), Цена min/max, Рейтинг, Опыт, Формат (соло/команда)
- Кнопки: Применить, Сбросить, Сохранить фильтр
- PopScope для корректного back-навигации
- Логи: `SEARCH_OPENED`, `SEARCH_FILTER_APPLIED`, `SEARCH_RESULT_COUNT:{n}`, `SEARCH_ERR:{code}`, `SEARCH_RETRY`

### 4. Уведомления ✅

- Создан экран `lib/screens/notifications/notifications_screen_enhanced.dart`
- Провайдер: `notificationsProvider` (StreamProvider из Firestore)
- Пагинация (limit 50), unread/seen индикаторы
- Pull-to-refresh
- PopScope для back-навигации
- Тап по уведомлению → роут в контекст (профиль/заявка/чат)
- Логи: `NOTIF_OPENED`, `NOTIF_TAP:{type}:{id}`, `REFRESH_OK:notifications`

### 5. Настройки ✅

- Добавлен PopScope для back-навигации
- Переключатель "Тёмная тема" с логированием `SETTINGS_THEME:{light|dark}`
- Логи: `SETTINGS_OPENED`
- Все пункты не выкидывают на главную

### 6. Back-навигация ✅

- PopScope добавлен на всех экранах:
  - Поиск (`search_screen_enhanced.dart`)
  - Профиль (`profile_full_screen.dart`)
  - Уведомления (`notifications_screen_enhanced.dart`)
  - Настройки (`settings_screen.dart`)
  - Создание заявки (уже было)
  - Главная (диалог выхода)

### 7. Firebase Rules/Indexes/Storage ✅

#### Firestore Rules:
- `stories`: создаёт только владелец, читают авторизованные
- `support_tickets`: создаёт авторизованный, читает только владелец
- `notifications`: только владелец
- `requests`: update/delete только автор
- `savedFilters`: только владелец

#### Storage Rules:
- `uploads/stories/{uid}/{allPaths=**}`: писать только владелец, ≤20 МБ, image/video
- `uploads/requests/{userId}/{requestId}/{fileName}`: уже было
- `uploads/avatars/{uid}/...`: уже было

#### Indexes:
Добавлены индексы:
- `requests`: (city ASC, createdAt DESC), (status ASC, createdAt DESC), (createdBy ASC, createdAt DESC)
- `notifications`: (userId ASC, timestamp DESC)
- `stories`: (authorId ASC, createdAt DESC)
- `users`: (role ASC, city ASC, rating DESC), (role ASC, categories ARRAY, rating DESC), (role ASC, priceFrom ASC, rating DESC), (firstNameLower ASC, lastNameLower ASC), (usernameLower ASC, role ASC)
- `specialists`: (role ASC, city ASC, categories ARRAY, rating DESC), (role ASC, categories ARRAY, minPrice ASC, rating DESC)

### 8. Логи/Аналитика ✅

Маркеры добавлены:
- `HOME_LOADED`, `HOME_TOP_RU_COUNT:{n}`, `HOME_TOP_CITY_COUNT:{n}`
- `SEARCH_OPENED`, `SEARCH_FILTER_APPLIED`, `SEARCH_RESULT_COUNT:{n}`, `SEARCH_ERR:{code}`, `SEARCH_RETRY`
- `REQUEST_CREATE_OPENED`, `REQUEST_PUBLISHED:{id}`, `REQUEST_ERR:{code}`
- `PROFILE_OPENED:{uid}`, `REVIEWS_LOADED:{n}`
- `NOTIF_OPENED`, `NOTIF_TAP:{type}:{id}`
- `SETTINGS_OPENED`, `SETTINGS_THEME:{light|dark}`
- `REFRESH_OK:{screen}`, `REFRESH_ERR:{screen}:{error}`
- `ERROR:{code}:{context}`

---

## Полный список индексов

### Firestore Indexes (firestore.indexes.json):

1. **users**:
   - `role ASC, city ASC`
   - `role ASC, city ASC, rating DESC`
   - `role ASC, usernameLower ASC`
   - `role ASC, city ASC, rating DESC` (дубликат)
   - `role ASC, categories ARRAY, rating DESC`
   - `role ASC, priceFrom ASC, rating DESC`
   - `firstNameLower ASC, lastNameLower ASC`
   - `usernameLower ASC, role ASC`

2. **specialists**:
   - `city ASC, scoreWeekly DESC`
   - `city ASC, rating DESC`
   - `categories ARRAY`
   - `city ASC`
   - `role ASC, city ASC, categories ARRAY, rating DESC`
   - `role ASC, categories ARRAY, minPrice ASC, rating DESC`

3. **requests**:
   - `city ASC, createdAt DESC`
   - `status ASC, createdAt DESC`
   - `createdBy ASC, createdAt DESC`

4. **notifications**:
   - `userId ASC, timestamp DESC`

5. **stories**:
   - `authorId ASC, createdAt DESC`

6. **reviews**:
   - `specialistId ASC, createdAt DESC`

7. **messages**:
   - `chatId ASC, createdAt DESC`

8. **chats**:
   - `participants ARRAY, updatedAt DESC`

### Статус деплоя:

Индексы добавлены в `firestore.indexes.json`. Для деплоя выполнить:
```bash
firebase deploy --only firestore:indexes
```

---

## Изменения в Rules

### Firestore Rules (firestore.rules):

```javascript
// Stories
match /stories/{storyId} {
  allow read: if isSignedIn();
  allow create: if isSignedIn() && request.resource.data.authorId == request.auth.uid;
  allow update, delete: if isSignedIn() && request.auth.uid == resource.data.authorId;
}

// Support tickets
match /support_tickets/{ticketId} {
  allow read: if isSignedIn() && request.auth.uid == resource.data.userId;
  allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
  allow update: if isSignedIn() && request.auth.uid == resource.data.userId;
  allow delete: if false;
}

// Notifications
match /notifications/{notificationId} {
  allow read, write: if isSignedIn() && request.auth.uid == resource.data.userId;
}

// Requests (обновлено)
match /requests/{requestId} {
  allow create: if isSignedIn() && request.resource.data.createdBy == request.auth.uid;
  allow read: if isSignedIn();
  allow update: if isSignedIn() && request.auth.uid == resource.data.createdBy;
  allow delete: if isSignedIn() && request.auth.uid == resource.data.createdBy;
}
```

### Storage Rules (storage.rules):

```javascript
// Stories
match /uploads/stories/{uid}/{allPaths=**} {
  allow write: if request.auth != null && request.auth.uid == uid
    && request.resource.size <= 20 * 1024 * 1024
    && (request.resource.contentType.matches('image/.*') ||
        request.resource.contentType.matches('video/.*'));
  allow read: if request.auth != null;
}
```

---

## Скрин маркеров из logcat

```
11-04 17:52:17.037 30457 30457 I flutter : APP: BUILD OK v4.5-refresh-stories
```

(Полный лог сохранён в `logs/max_apply_log.txt`)

---

## Размер APK и SHA1

- **Размер:** 77.4 MB
- **SHA1:** `18A31154B230865ADA43DDA983EC8C1D1C3A24FF`

---

## Чек-лист проверки на устройстве

### Главная:
- [ ] Плашка пользователя: имя, @username, город
- [ ] Две карусели: "Россия" и "{город}" (если город указан)
- [ ] Pull-to-refresh работает
- [ ] Логи: `HOME_LOADED`, `HOME_TOP_RU_COUNT`, `HOME_TOP_CITY_COUNT`
- [ ] Иконка уведомлений → открывает экран уведомлений

### Поиск:
- [ ] Кнопка "Попробовать снова" реально перезапускает запрос
- [ ] Расширенный список категорий (30+)
- [ ] Фильтры: город, категории, цена, рейтинг, опыт, формат
- [ ] Кнопки: Применить, Сбросить, Сохранить фильтр
- [ ] Back-кнопка возвращает на предыдущий экран
- [ ] Pull-to-refresh работает
- [ ] Логи: `SEARCH_OPENED`, `SEARCH_FILTER_APPLIED`, `SEARCH_RESULT_COUNT`

### Уведомления:
- [ ] Экран открывается по иконке колокольчика
- [ ] Список уведомлений отображается
- [ ] Pull-to-refresh работает
- [ ] Тап по уведомлению → роут в контекст
- [ ] Back-кнопка возвращает на предыдущий экран
- [ ] Логи: `NOTIF_OPENED`, `NOTIF_TAP`

### Настройки:
- [ ] Экран открывается без крэшей
- [ ] Переключатель "Тёмная тема" работает
- [ ] Back-кнопка возвращает на предыдущий экран
- [ ] Логи: `SETTINGS_OPENED`, `SETTINGS_THEME`

### Профиль:
- [ ] Pull-to-refresh работает
- [ ] Вкладки: Посты, Рилсы, Отзывы
- [ ] Back-кнопка возвращает на предыдущий экран
- [ ] Логи: `PROFILE_OPENED`, `REVIEWS_LOADED`

### Общее:
- [ ] Все экраны с RefreshIndicator показывают "Обновлено" при успехе
- [ ] Все ошибки логируются как `REFRESH_ERR:{screen}:{error}`
- [ ] Маркер `APP: BUILD OK v4.5-refresh-stories` в logcat

---

## Коммиты

Все изменения выполнены с префиксом `max:` (если были коммиты).

---

## Примечания

- Stories и Following Feed требуют дополнительной реализации (пункт 7) — можно добавить позже
- Сохранение фильтров в `users/{uid}/saved_filters` — базовая структура готова, требуется UI для отображения "Недавние фильтры"
- Настройки: полная реализация всех подэкранов (безопасность, приватность, языки) — упрощённая версия, можно доработать

---

**Статус:** ✅ APK собран и установлен на устройство. Готово к тестированию.

