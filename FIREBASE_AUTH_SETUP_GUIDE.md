# 🔥 Firebase Authentication Setup Guide

## 📋 Обязательные настройки в Firebase Console

### 1. 🔐 Authentication Methods

Перейдите в Firebase Console → Authentication → Sign-in method и включите:

#### ✅ Email/Password
- Включить "Email/Password" 
- Включить "Email link (passwordless sign-in)" (опционально)

#### ✅ Google Sign-In
- Включить "Google"
- Добавить SHA-1 и SHA-256 ключи:
  ```
  SHA-1: 8A:04:3E:65:47:27:BB:E9:69:5A:E5:21:F2:67:68:BF:62:ED:C9:F8
  SHA-256: 6D:9E:0A:CF:57:F0:06:D6:62:E3:00:7E:EB:C6:17:F5:E8:1E:65:10:7B:13:DC:DF:EC:C8:ED:78:FE:86:FC:98
  ```

#### ✅ Phone Authentication
- Включить "Phone"
- Настроить биллинг (требуется для SMS)
- Выбрать регион (Russia для +7 номеров)

### 2. 🔑 OAuth Client Configuration

В Google Cloud Console → Credentials:

1. Найдите OAuth 2.0 Client ID для Android
2. Убедитесь, что Package name: `com.eventmarketplace.app`
3. Добавьте SHA-1 fingerprint: `8A:04:3E:65:47:27:BB:E9:69:5A:E5:21:F2:67:68:BF:62:ED:C9:F8`

### 3. 📱 Firebase Project Settings

В Firebase Console → Project Settings:

1. **General**:
   - Project ID: `event-marketplace-mvp`
   - Project Number: `272201705683`

2. **Your apps** → Android app:
   - Package name: `com.eventmarketplace.app`
   - SHA-1: `8A:04:3E:65:47:27:BB:E9:69:5A:E5:21:F2:67:68:BF:62:ED:C9:F8`
   - SHA-256: `6D:9E:0A:CF:57:F0:06:D6:62:E3:00:7E:EB:C6:17:F5:E8:1E:65:10:7B:13:DC:DF:EC:C8:ED:78:FE:86:FC:98`

### 4. 💳 Billing Setup (для Phone Auth)

1. Перейдите в Google Cloud Console → Billing
2. Подключите платежный метод
3. Включите Firebase Authentication API
4. Настройте квоты для SMS (по умолчанию 10 SMS/день для тестирования)

### 5. 🔧 Firestore Security Rules

Убедитесь, что в Firestore Rules настроены права доступа:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public read access for specialists
    match /specialists/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 🧪 Тестирование

### Email/Password Auth
1. Откройте приложение
2. Нажмите "Регистрация"
3. Введите email, пароль, имя
4. Проверьте, что создается профиль в Firestore
5. Выйдите и войдите снова

### Google Sign-In
1. Нажмите "Войти через Google"
2. Выберите аккаунт Google
3. Проверьте, что нет ошибки "ApiException: 10"
4. Проверьте создание профиля в Firestore

### Phone Auth
1. Нажмите "Войти по телефону"
2. Введите номер +7XXXXXXXXXX
3. Проверьте получение SMS
4. Введите код из SMS
5. Проверьте создание профиля в Firestore

## 🚨 Troubleshooting

### Google Sign-In Error 10
- Проверьте SHA-1 в Firebase Console
- Убедитесь, что OAuth Client ID правильный
- Проверьте, что google-services.json актуален

### Phone Auth BILLING_NOT_ENABLED
- Включите биллинг в Google Cloud Console
- Активируйте Firebase Authentication API
- Проверьте, что Phone Auth включен в Firebase Console

### Email Auth не работает
- Проверьте, что Email/Password включен в Firebase Console
- Убедитесь, что Firestore Rules разрешают запись
- Проверьте логи на ошибки Firebase

## 📞 Поддержка

Если проблемы остаются:
1. Проверьте логи: `adb logcat -s flutter`
2. Убедитесь, что все настройки в Firebase Console применены
3. Пересоберите приложение после изменений в Firebase
