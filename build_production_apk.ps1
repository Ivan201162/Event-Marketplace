# Скрипт для сборки production APK для тестирования с 10 пользователями
# Event Marketplace App

Write-Host "🚀 Начинаем сборку production APK для Event Marketplace App" -ForegroundColor Green

# Проверяем, что мы в правильной директории
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Ошибка: pubspec.yaml не найден. Запустите скрипт из корневой директории проекта." -ForegroundColor Red
    exit 1
}

Write-Host "📋 Шаг 1: Очистка проекта" -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при очистке проекта" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Шаг 2: Получение зависимостей" -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при получении зависимостей" -ForegroundColor Red
    exit 1
}

Write-Host "🔧 Шаг 3: Проверка конфигурации" -ForegroundColor Yellow

# Проверяем конфигурацию Supabase
$supabaseConfigPath = "lib/config/supabase_config.dart"
if (Test-Path $supabaseConfigPath) {
    $configContent = Get-Content $supabaseConfigPath -Raw
    if ($configContent -match "your-project-id\.supabase\.co" -or $configContent -match "your-anon-key-here") {
        Write-Host "⚠️  ВНИМАНИЕ: Supabase не настроен! Обновите lib/config/supabase_config.dart" -ForegroundColor Yellow
        Write-Host "   URL: https://your-project-id.supabase.co" -ForegroundColor Yellow
        Write-Host "   Anon Key: your-anon-key-here" -ForegroundColor Yellow
        Write-Host "   Продолжаем сборку с тестовыми данными..." -ForegroundColor Yellow
    } else {
        Write-Host "✅ Supabase конфигурация найдена" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  Файл конфигурации Supabase не найден" -ForegroundColor Yellow
}

Write-Host "🏗️  Шаг 4: Сборка debug APK" -ForegroundColor Yellow
flutter build apk --debug --no-shrink
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при сборке debug APK" -ForegroundColor Red
    exit 1
}

Write-Host "🏗️  Шаг 5: Сборка release APK" -ForegroundColor Yellow
flutter build apk --release --no-shrink
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при сборке release APK" -ForegroundColor Red
    exit 1
}

Write-Host "📱 Шаг 6: Проверка APK файлов" -ForegroundColor Yellow

$debugApk = "build/app/outputs/flutter-apk/app-debug.apk"
$releaseApk = "build/app/outputs/flutter-apk/app-release.apk"

if (Test-Path $debugApk) {
    $debugSize = (Get-Item $debugApk).Length / 1MB
    Write-Host "✅ Debug APK создан: $debugApk (${$debugSize.ToString('F1')} MB)" -ForegroundColor Green
} else {
    Write-Host "❌ Debug APK не найден" -ForegroundColor Red
}

if (Test-Path $releaseApk) {
    $releaseSize = (Get-Item $releaseApk).Length / 1MB
    Write-Host "✅ Release APK создан: $releaseApk (${$releaseSize.ToString('F1')} MB)" -ForegroundColor Green
} else {
    Write-Host "❌ Release APK не найден" -ForegroundColor Red
}

Write-Host "📋 Шаг 7: Создание папки для распространения" -ForegroundColor Yellow
$distributionDir = "dist"
if (-not (Test-Path $distributionDir)) {
    New-Item -ItemType Directory -Path $distributionDir
}

# Копируем APK файлы
if (Test-Path $debugApk) {
    Copy-Item $debugApk "$distributionDir/EventMarketplace_Debug.apk"
    Write-Host "📦 Debug APK скопирован в $distributionDir/EventMarketplace_Debug.apk" -ForegroundColor Green
}

if (Test-Path $releaseApk) {
    Copy-Item $releaseApk "$distributionDir/EventMarketplace_Release.apk"
    Write-Host "📦 Release APK скопирован в $distributionDir/EventMarketplace_Release.apk" -ForegroundColor Green
}

# Создаем README для тестировщиков
$readmeContent = @"
# Event Marketplace App - Версия для тестирования

## Установка
1. Скачайте APK файл на ваше Android устройство
2. Разрешите установку из неизвестных источников в настройках
3. Установите приложение

## Тестирование
Протестируйте следующие функции:

### ✅ Авторизация
- [ ] Регистрация через email
- [ ] Вход через email
- [ ] Вход через телефон (SMS)
- [ ] Гостевой режим

### ✅ Профиль
- [ ] Создание профиля
- [ ] Редактирование профиля
- [ ] Загрузка аватара
- [ ] Добавление навыков

### ✅ Социальные функции
- [ ] Просмотр ленты идей
- [ ] Создание постов
- [ ] Лайки и комментарии
- [ ] Подписки на пользователей

### ✅ Чаты
- [ ] Список чатов
- [ ] Отправка сообщений
- [ ] Realtime обновления

### ✅ Заявки
- [ ] Создание заявок
- [ ] Просмотр "Мои заявки"
- [ ] Просмотр "Заявки мне"
- [ ] Обновление статуса

### ✅ Поиск и фильтры
- [ ] Поиск пользователей
- [ ] Фильтры по городу/категории
- [ ] Топ специалистов недели

## Отчеты об ошибках
При обнаружении ошибок сообщите:
1. Описание проблемы
2. Шаги для воспроизведения
3. Модель устройства и версия Android
4. Скриншоты (если возможно)

## Контакты
Для вопросов и предложений обращайтесь к разработчику.

---
Версия: 1.2-stable
Дата сборки: $(Get-Date -Format "yyyy-MM-dd HH:mm")
"@

Set-Content -Path "$distributionDir/README.md" -Value $readmeContent -Encoding UTF8
Write-Host "📄 README создан: $distributionDir/README.md" -ForegroundColor Green

Write-Host "🎉 Сборка завершена успешно!" -ForegroundColor Green
Write-Host "📁 APK файлы находятся в папке: $distributionDir" -ForegroundColor Cyan
Write-Host "📱 Готово для тестирования с 10 пользователями!" -ForegroundColor Cyan

Write-Host "`n📋 Следующие шаги:" -ForegroundColor Yellow
Write-Host "1. Настройте Supabase (если еще не сделано)" -ForegroundColor White
Write-Host "2. Раздайте APK файлы тестировщикам" -ForegroundColor White
Write-Host "3. Соберите обратную связь" -ForegroundColor White
Write-Host "4. Исправьте найденные ошибки" -ForegroundColor White
Write-Host "5. Создайте финальную версию" -ForegroundColor White

Write-Host "`n🔗 Полезные ссылки:" -ForegroundColor Yellow
Write-Host "- Supabase Dashboard: https://supabase.com/dashboard" -ForegroundColor White
Write-Host "- Flutter Docs: https://docs.flutter.dev" -ForegroundColor White
Write-Host "- Android Debug Bridge: https://developer.android.com/studio/command-line/adb" -ForegroundColor White
