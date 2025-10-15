# Скрипт для сборки и установки приложения на Android устройство
# Event Marketplace App - Build and Install Script

Write-Host "🚀 Event Marketplace App - Сборка и установка" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Проверяем, что мы в правильной директории
if (-not (Test-Path "pubspec.yaml")) {
  Write-Host "❌ Ошибка: pubspec.yaml не найден. Запустите скрипт из корневой директории проекта." -ForegroundColor Red
  exit 1
}

Write-Host "📱 Начинаем сборку приложения..." -ForegroundColor Yellow

# Очистка проекта
Write-Host "🧹 Очистка проекта..." -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Ошибка при очистке проекта" -ForegroundColor Red
  exit 1
}

# Получение зависимостей
Write-Host "📦 Получение зависимостей..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Ошибка при получении зависимостей" -ForegroundColor Red
  exit 1
}

# Проверка подключенных устройств
Write-Host "🔍 Проверка подключенных устройств..." -ForegroundColor Cyan
$devices = flutter devices --machine | ConvertFrom-Json
$androidDevices = $devices | Where-Object { $_.platformType -eq "android" -and $_.emulator -eq $false }

if ($androidDevices.Count -eq 0) {
  Write-Host "❌ Не найдено подключенных Android устройств" -ForegroundColor Red
  Write-Host "💡 Убедитесь, что:" -ForegroundColor Yellow
  Write-Host "   - Устройство подключено по USB" -ForegroundColor Yellow
  Write-Host "   - Включена отладка по USB" -ForegroundColor Yellow
  Write-Host "   - Устройство авторизовано для разработки" -ForegroundColor Yellow
  exit 1
}

Write-Host "✅ Найдено Android устройств: $($androidDevices.Count)" -ForegroundColor Green
foreach ($device in $androidDevices) {
  Write-Host "   📱 $($device.name) ($($device.id))" -ForegroundColor White
}

# Сборка APK
Write-Host "🔨 Сборка APK..." -ForegroundColor Cyan
flutter build apk --debug
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Ошибка при сборке APK" -ForegroundColor Red
  exit 1
}

Write-Host "✅ APK успешно собран!" -ForegroundColor Green

# Установка на устройство
Write-Host "📲 Установка на устройство..." -ForegroundColor Cyan
flutter install
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Ошибка при установке на устройство" -ForegroundColor Red
  exit 1
}

Write-Host "✅ Приложение успешно установлено!" -ForegroundColor Green

# Запуск приложения
Write-Host "🚀 Запуск приложения..." -ForegroundColor Cyan
flutter run --debug
if ($LASTEXITCODE -ne 0) {
  Write-Host "⚠️  Приложение установлено, но не удалось запустить автоматически" -ForegroundColor Yellow
  Write-Host "💡 Запустите приложение вручную на устройстве" -ForegroundColor Yellow
}

Write-Host "🎉 Готово! Приложение установлено и готово к тестированию" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Информация о тестировании
Write-Host "📋 Что протестировать:" -ForegroundColor Yellow
Write-Host "   ✅ Работа фильтров на главном экране" -ForegroundColor White
Write-Host "   ✅ Удаление блока быстрых действий" -ForegroundColor White
Write-Host "   ✅ Разделение заявок на 'Мои заявки' и 'Заявки мне'" -ForegroundColor White
Write-Host "   ✅ Добавление публикаций в 'Идеях' (FAB + форма)" -ForegroundColor White
Write-Host "   ✅ Редактирование профиля" -ForegroundColor White
Write-Host "   ✅ Вход по телефону (видимые вкладки)" -ForegroundColor White
Write-Host "   ✅ Адаптация под мобильные устройства" -ForegroundColor White

Write-Host "`n🔧 Полезные команды:" -ForegroundColor Cyan
Write-Host "   flutter logs          - Просмотр логов" -ForegroundColor White
Write-Host "   flutter devices       - Список устройств" -ForegroundColor White
Write-Host "   flutter run --hot     - Горячая перезагрузка" -ForegroundColor White
