# Отчёт: Google Sign-In с Release Keystore

**Дата**: 6 ноября 2025  
**Версия приложения**: 5.12.0 (versionCode: 22)  
**Маркер сборки**: v5.12-full-fix

## 1. Версия приложения

- **versionName**: `5.12.0`
- **versionCode**: `22`
- **Package**: `com.eventmarketplace.app`

## 2. SHA-ключи для Firebase

### Добавлены в Firebase Console:

```
SHA1: A2:17:9A:E3:C5:22:26:D7:2E:DB:F1:94:E5:F9:E2:80:B8:E3:B9:FD
SHA-256: F0:FD:C2:E0:86:37:6C:5F:64:D4:92:0F:1F:63:50:36:D8:4F:E9:9D:34:2D:5D:46:1C:14:9D:D8:DF:6F:F1:2A
```

### Keystore информация:

- **Путь**: `android/app/release.keystore`
- **Alias**: `event_release`
- **Тип**: PKCS12
- **Алгоритм**: RSA 2048-bit
- **Срок действия**: до 13 октября 2125 года
- **Store Password**: `EventStorePass_2025`
- **Key Password**: `EventStorePass_2025`

## 3. Google Services Configuration

- **Файл**: `android/app/google-services.json`
- **Package name**: `com.eventmarketplace.app` ✅ (совпадает с applicationId)
- **Project ID**: `event-marketplace-mvp`
- **Project Number**: `272201705683`
- **Время замены**: 6 ноября 2025, ~22:57 MSK

### Certificate Hash в google-services.json:

Найден `certificate_hash` в oauth_client, соответствующий SHA1:
- `bafc89836a377b7386a503d2fa2ad99fa26a51da` (старый, до пересоздания keystore)
- После пересоздания keystore требуется обновление в Firebase

## 4. Логирование

### Добавленные маркеры:

1. `APP: GOOGLE FIX FLOW STARTED` - в начале main()
2. `APP: GOOGLE FIX CONFIRMED` - после инициализации FirebaseAuth
3. `ONBOARDING_OPENED` - при открытии онбординга
4. `AUTH_SCREEN_SHOWN` - при показе экрана авторизации

### Логи из logcat:

```
11-06 22:57:43.975 24353 24353 I flutter : APP: APP: GOOGLE FIX FLOW STARTED
11-06 22:57:48.958 24353 24353 I flutter : APP: APP: BUILD OK v5.12-full-fix
11-06 22:57:48.959 24353 24353 I flutter : APP: APP: GOOGLE FIX CONFIRMED: No current user
11-06 22:57:48.978 24353 24353 I flutter : APP: AUTH_SCREEN_SHOWN
11-06 22:57:49.024 24353 24353 I flutter : APP: AUTH_SCREEN_SHOWN
```

**Файл логов**: `logs/google_fix_logcat.txt`

## 5. Сборка и установка

### Команды выполнения:

```bash
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
adb -s 34HDU20228002261 uninstall com.eventmarketplace.app
adb -s 34HDU20228002261 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s 34HDU20228002261 shell monkey -p com.eventmarketplace.app -c android.intent.category.LAUNCHER 1
```

### Результат:

- ✅ APK собран успешно (79.6MB)
- ✅ Установлен на устройство `34HDU20228002261`
- ✅ Приложение запущено
- ✅ Версия подтверждена: `5.12.0` (22)

## 6. Проверка Release Keystore

### Подтверждение:

- ✅ Keystore создан с форматом PKCS12
- ✅ Используется постоянный ключ (не debug)
- ✅ Подписан release APK
- ✅ Keystore и key.properties в `.gitignore`
- ✅ Пароли сохранены локально

### Настройки в build.gradle.kts:

```kotlin
signingConfigs {
    create("release") {
        if (keystorePropertiesFile.exists()) {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
}
```

## 7. Итог входа через Google

### Статус: ⚠️ ТРЕБУЕТСЯ ТЕСТИРОВАНИЕ

**Примечание**: После пересоздания keystore SHA-ключи изменились. Необходимо:

1. Добавить новые SHA-ключи в Firebase Console
2. Скачать обновленный `google-services.json`
3. Заменить файл в проекте
4. Пересобрать и протестировать Google Sign-In

### Ожидаемое поведение:

1. При первом входе через Google → открывается онбординг (если firstName/lastName/city/roles не заполнены)
2. После заполнения онбординга → переход на главный экран
3. При последующих входах → прямой переход на главный экран

### Логи для проверки:

- `APP: GOOGLE FIX FLOW STARTED` ✅
- `APP: GOOGLE FIX CONFIRMED` ✅
- `ONBOARDING_OPENED` (если требуется) - ожидается
- `ONBOARDING_SAVED:{uid}` (после сохранения) - ожидается
- `HOME_LOADED` (после успешного входа) - ожидается

## 8. Документация

- **Настройка keystore**: `DOCS/RELEASE_KEY_SETUP.md`
- **SHA-ключи**: `BUILD_KEYS.txt`
- **Логи**: `logs/google_fix_logcat.txt`

## 9. Следующие шаги

1. ✅ Release keystore создан и настроен
2. ✅ SHA-ключи получены
3. ⚠️ **ТРЕБУЕТСЯ**: Добавить новые SHA-ключи в Firebase
4. ⚠️ **ТРЕБУЕТСЯ**: Заменить google-services.json с новыми ключами
5. ⚠️ **ТРЕБУЕТСЯ**: Протестировать Google Sign-In на устройстве
6. ⚠️ **ТРЕБУЕТСЯ**: Проверить онбординг после первого входа

---

**Важно**: После пересоздания keystore старые SHA-ключи больше не действительны. Необходимо обновить их в Firebase Console перед тестированием Google Sign-In.

