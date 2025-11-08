# Настройка Release Keystore для Android

## Шаги настройки

### 1. Создание release.keystore

```bash
cd android/app
keytool -genkeypair -v -storetype PKCS12 -keystore release.keystore \
  -alias event_release \
  -keyalg RSA -keysize 2048 -validity 36500 \
  -storepass EventStorePass_2025 \
  -keypass EventStorePass_2025 \
  -dname "CN=EventMarketplace, OU=Prod, O=Event, L=Moscow, S=Moscow, C=RU"
```

### 2. Создание key.properties

Создать файл `android/key.properties`:

```
storePassword=EventStorePass_2025
keyPassword=EventStorePass_2025
keyAlias=event_release
storeFile=app/release.keystore
```

### 3. Получение SHA-ключей

```bash
cd android/app
keytool -list -v -alias event_release -keystore release.keystore -storepass EventStorePass_2025
```

Найти в выводе:
- SHA1: ...
- SHA-256: ...

### 4. Добавление SHA-ключей в Firebase

1. Открыть Firebase Console → Project Settings
2. Выбрать Android app
3. В разделе "SHA certificate fingerprints" добавить оба ключа (SHA-1 и SHA-256)
4. Скачать обновленный `google-services.json`
5. Заменить `android/app/google-services.json`

### 5. Проверка package_name

Убедиться, что `package_name` в `google-services.json` совпадает с `applicationId` в `android/app/build.gradle.kts`:
- `package_name`: `com.eventmarketplace.app`
- `applicationId`: `com.eventmarketplace.app`

### 6. Сборка release APK

```bash
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

## Важные замечания

- `release.keystore` и `key.properties` должны быть в `.gitignore`
- НЕ коммитить эти файлы в Git
- Сохранить пароли в безопасном месте
- Keystore действителен до 2125 года

## Текущие параметры

- **Keystore**: `android/app/release.keystore`
- **Alias**: `event_release`
- **Store Password**: `EventStorePass_2025`
- **Key Password**: `EventStorePass_2025`
- **Valid until**: Sat Oct 13 22:56:23 KRAT 2125

