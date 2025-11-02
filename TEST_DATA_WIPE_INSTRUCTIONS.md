# 🗑️ TEST DATA WIPE INSTRUCTIONS

**⚠️ ВНИМАНИЕ:** Эта операция удалит ВСЕ тестовые данные из Firestore и Storage. Выполнять только после создания резервной копии!

---

## 📋 ПЕРЕД ВЫПОЛНЕНИЕМ

1. **Создать резервную копию БД:**
   ```bash
   firebase firestore:export gs://event-marketplace-mvp.appspot.com/backups/backup_$(date +%Y%m%d_%H%M%S)
   ```

2. **Проверить что вы находитесь в правильном проекте:**
   ```bash
   firebase projects:list
   firebase use event-marketplace-mvp
   ```

---

## 🔥 FIRESTORE COLLECTIONS TO DELETE

### Команды для удаления:

```bash
# Основные коллекции
firebase firestore:delete --project event-marketplace-mvp --recursive --force users
firebase firestore:delete --project event-marketplace-mvp --recursive --force user_profiles
firebase firestore:delete --project event-marketplace-mvp --recursive --force specialists
firebase firestore:delete --project event-marketplace-mvp --recursive --force posts
firebase firestore:delete --project event-marketplace-mvp --recursive --force ideas
firebase firestore:delete --project event-marketplace-mvp --recursive --force follows
firebase firestore:delete --project event-marketplace-mvp --recursive --force requests
firebase firestore:delete --project event-marketplace-mvp --recursive --force chats
firebase firestore:delete --project event-marketplace-mvp --recursive --force messages
firebase firestore:delete --project event-marketplace-mvp --recursive --force notifications
firebase firestore:delete --project event-marketplace-mvp --recursive --force stories
firebase firestore:delete --project event-marketplace-mvp --recursive --force categories
firebase firestore:delete --project event-marketplace-mvp --recursive --force tariffs
firebase firestore:delete --project event-marketplace-mvp --recursive --force plans
firebase firestore:delete --project event-marketplace-mvp --recursive --force feed

# Subcollections (удалятся автоматически при удалении родительских документов)
# post_likes, post_comments (subcollections of posts)
# idea_likes, idea_comments (subcollections of ideas)
```

---

## 💾 STORAGE PATHS TO DELETE

### Команды для удаления:

```bash
# Удалить все uploads
gsutil -m rm -r gs://event-marketplace-mvp.appspot.com/uploads/posts/**
gsutil -m rm -r gs://event-marketplace-mvp.appspot.com/uploads/reels/**
gsutil -m rm -r gs://event-marketplace-mvp.appspot.com/uploads/ideas/**
gsutil -m rm -r gs://event-marketplace-mvp.appspot.com/uploads/avatars/**
gsutil -m rm -r gs://event-marketplace-mvp.appspot.com/uploads/stories/**

# Или удалить всю папку uploads
gsutil -m rm -r gs://event-marketplace-mvp.appspot.com/uploads/
```

---

## 📝 АЛЬТЕРНАТИВНЫЙ МЕТОД: ЧЕРЕЗ FIREBASE CONSOLE

### Firestore:
1. Открыть Firebase Console → Firestore Database
2. Для каждой коллекции:
   - Выбрать коллекцию
   - Выбрать все документы (Ctrl+A)
   - Нажать "Delete" → Подтвердить

### Storage:
1. Открыть Firebase Console → Storage
2. Перейти в папку `uploads/`
3. Удалить папки: `posts`, `reels`, `ideas`, `avatars`, `stories`

---

## ✅ ПРОВЕРКА ПОСЛЕ УДАЛЕНИЯ

1. **Проверить Firestore:**
   ```bash
   firebase firestore:collections --project event-marketplace-mvp
   ```
   Убедиться что указанные коллекции пусты или удалены

2. **Проверить Storage:**
   ```bash
   gsutil ls gs://event-marketplace-mvp.appspot.com/uploads/
   ```
   Убедиться что папки удалены или пусты

3. **Проверить приложение:**
   - Запустить приложение
   - Проверить что нет старых данных
   - Создать новый аккаунт и проверить работу

---

## 🔄 ВОССТАНОВЛЕНИЕ ИЗ РЕЗЕРВНОЙ КОПИИ

Если нужно восстановить данные:

```bash
# Импорт резервной копии
firebase firestore:import gs://event-marketplace-mvp.appspot.com/backups/backup_YYYYMMDD_HHMMSS
```

---

## ⚠️ ВАЖНЫЕ ЗАМЕЧАНИЯ

1. **НЕ удалять системные коллекции:**
   - `_firestore_metadata` (системная)
   - Другие системные коллекции Firebase

2. **Проверить перед удалением:**
   - Убедиться что есть резервная копия
   - Убедиться что проект правильный (event-marketplace-mvp)
   - Убедиться что это production проект (не staging/dev)

3. **Время выполнения:**
   - Firestore: ~5-10 минут для больших коллекций
   - Storage: ~10-30 минут в зависимости от размера

---

## 📞 ПОДДЕРЖКА

При возникновении проблем:
1. Проверить логи Firebase Console
2. Проверить права доступа к проекту
3. Убедиться что Firebase CLI обновлён: `firebase --version`

---

**Инструкция создана:** 2025-01-27  
**Статус:** Готово к выполнению (требует ручного подтверждения)

