# Инструкции по настройке Firebase для Event Marketplace App

## 🔧 Настройка Firebase Console

### 1. Включение Authentication

1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Выберите проект `event-marketplace-mvp`
3. Перейдите в **Authentication** → **Sign-in method**
4. Включите следующие провайдеры:

#### Email/Password
- ✅ Включить
- ✅ Email link (passwordless sign-in) - опционально

#### Google
- ✅ Включить
- Web client ID: `1:272201705683:web:057887a281175671f80c26`
- Web client secret: (автоматически генерируется)

#### Anonymous
- ✅ Включить

### 2. Настройка Authorized Domains

В **Authentication** → **Settings** → **Authorized domains** добавить:

- `localhost`
- `127.0.0.1`
- `event-marketplace-mvp.firebaseapp.com`
- `event-marketplace-mvp.web.app`

### 3. Настройка Firestore Database

1. Перейдите в **Firestore Database**
2. Создайте базу данных в режиме **test mode** (для разработки)
3. Выберите регион (например, `us-central1`)

### 4. Настройка Storage

1. Перейдите в **Storage**
2. Создайте bucket
3. Настройте правила безопасности

### 5. Настройка Cloud Functions (для VK)

1. Перейдите в **Functions**
2. Убедитесь, что функции развернуты
3. Настройте переменные окружения для VK:
   - `VK_CLIENT_ID`
   - `VK_CLIENT_SECRET`
   - `VK_REDIRECT_URI`

## 🔑 Текущая конфигурация

```json
{
  "projectId": "event-marketplace-mvp",
  "appId": "1:272201705683:web:057887a281175671f80c26",
  "storageBucket": "event-marketplace-mvp.firebasestorage.app",
  "apiKey": "AIzaSyBcNT54NuncA9Nck-5VQYdbnxwl5pdzsmA",
  "authDomain": "event-marketplace-mvp.firebaseapp.com",
  "messagingSenderId": "272201705683"
}
```

## 🚀 Следующие шаги

1. Выполнить настройки в Firebase Console
2. Протестировать аутентификацию
3. Проверить все методы входа
4. Создать финальный отчет

## ⚠️ Важно

- Убедитесь, что все домены добавлены в Authorized domains
- Проверьте, что все провайдеры аутентификации включены
- Убедитесь, что Firestore и Storage настроены

