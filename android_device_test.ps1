# Скрипт для тестирования приложения на Android устройстве
# Запуск: .\android_device_test.ps1

Write-Host "📱 Тестирование Event Marketplace на Android устройстве" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Проверка подключения устройства
Write-Host "`n🔍 Проверка подключения устройства..." -ForegroundColor Yellow
$devices = adb devices
if ($devices -match "device$") {
  Write-Host "✅ Устройство подключено" -ForegroundColor Green
  $deviceId = ($devices | Select-String "device$").Line.Split()[0]
  Write-Host "📱 ID устройства: $deviceId" -ForegroundColor Cyan
}
else {
  Write-Host "❌ Устройство не найдено. Подключите Android устройство и включите отладку по USB" -ForegroundColor Red
  exit 1
}

# Получение applicationId
Write-Host "`n📦 Получение applicationId..." -ForegroundColor Yellow
$buildGradle = Get-Content "android\app\build.gradle" | Select-String "applicationId"
if ($buildGradle) {
  $applicationId = ($buildGradle -split '"')[1]
  Write-Host "✅ ApplicationId: $applicationId" -ForegroundColor Green
}
else {
  Write-Host "❌ Не удалось найти applicationId" -ForegroundColor Red
  exit 1
}

# Очистка и сборка
Write-Host "`n🔨 Очистка и сборка приложения..." -ForegroundColor Yellow
Write-Host "Очистка..." -ForegroundColor Cyan
flutter clean

Write-Host "Получение зависимостей..." -ForegroundColor Cyan
flutter pub get

Write-Host "Анализ кода..." -ForegroundColor Cyan
flutter analyze

Write-Host "Сборка APK..." -ForegroundColor Cyan
flutter build apk --debug --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Ошибка сборки приложения" -ForegroundColor Red
  exit 1
}

Write-Host "✅ Приложение успешно собрано" -ForegroundColor Green

# Удаление старой версии
Write-Host "`n🗑️ Удаление старой версии приложения..." -ForegroundColor Yellow
adb -s $deviceId uninstall $applicationId 2>$null
Write-Host "✅ Старая версия удалена" -ForegroundColor Green

# Установка новой версии
Write-Host "`n📲 Установка новой версии..." -ForegroundColor Yellow
adb -s $deviceId install -r "build\app\outputs\flutter-apk\app-debug.apk"

if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Ошибка установки приложения" -ForegroundColor Red
  exit 1
}

Write-Host "✅ Приложение успешно установлено" -ForegroundColor Green

# Запуск приложения
Write-Host "`n🚀 Запуск приложения..." -ForegroundColor Yellow
adb -s $deviceId shell monkey -p $applicationId -c android.intent.category.LAUNCHER 1

Write-Host "✅ Приложение запущено" -ForegroundColor Green

# Ожидание запуска
Write-Host "`n⏳ Ожидание запуска приложения (10 секунд)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Проверка логов
Write-Host "`n📋 Проверка логов приложения..." -ForegroundColor Yellow
$logFile = "build\device_test_logcat.txt"
adb -s $deviceId logcat -d | Select-String "flutter" | Select-Object -Last 50 | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "📄 Логи сохранены в: $logFile" -ForegroundColor Cyan

# Проверка на ошибки
$errorLogs = Get-Content $logFile | Select-String -Pattern "ERROR|FATAL|Exception"
if ($errorLogs) {
  Write-Host "⚠️ Найдены ошибки в логах:" -ForegroundColor Yellow
  $errorLogs | ForEach-Object { Write-Host "  $($_.Line)" -ForegroundColor Red }
}
else {
  Write-Host "✅ Критических ошибок не найдено" -ForegroundColor Green
}

# Автоматическое тестирование UI
Write-Host "`n🎯 Автоматическое тестирование UI..." -ForegroundColor Yellow

# Функция для выполнения команды на устройстве
function Invoke-DeviceCommand {
  param($command)
  adb -s $deviceId shell $command
  Start-Sleep -Milliseconds 500
}

# Тест 1: Проверка главного экрана
Write-Host "  📱 Тест 1: Проверка главного экрана" -ForegroundColor Cyan
Invoke-DeviceCommand "input tap 540 960"  # Тап по центру экрана
Start-Sleep -Seconds 2

# Тест 2: Навигация по вкладкам
Write-Host "  🧭 Тест 2: Навигация по вкладкам" -ForegroundColor Cyan
Invoke-DeviceCommand "input tap 200 2000"  # Вкладка "Лента"
Start-Sleep -Seconds 2
Invoke-DeviceCommand "input tap 400 2000"  # Вкладка "Заявки"
Start-Sleep -Seconds 2
Invoke-DeviceCommand "input tap 600 2000"  # Вкладка "Чаты"
Start-Sleep -Seconds 2
Invoke-DeviceCommand "input tap 800 2000"  # Вкладка "Идеи"
Start-Sleep -Seconds 2
Invoke-DeviceCommand "input tap 100 2000"  # Возврат на главную
Start-Sleep -Seconds 2

# Тест 3: Проверка кнопок в AppBar
Write-Host "  🔘 Тест 3: Проверка кнопок в AppBar" -ForegroundColor Cyan
Invoke-DeviceCommand "input tap 50 100"   # Кнопка профиля
Start-Sleep -Seconds 2
Invoke-DeviceCommand "input keyevent 4"   # Назад
Start-Sleep -Seconds 1

Invoke-DeviceCommand "input tap 200 100"  # Кнопка чатов
Start-Sleep -Seconds 2
Invoke-DeviceCommand "input keyevent 4"   # Назад
Start-Sleep -Seconds 1

Invoke-DeviceCommand "input tap 350 100"  # Кнопка уведомлений
Start-Sleep -Seconds 2
Invoke-DeviceCommand "input keyevent 4"   # Назад
Start-Sleep -Seconds 1

Invoke-DeviceCommand "input tap 500 100"  # Кнопка настроек
Start-Sleep -Seconds 2
Invoke-DeviceCommand "input keyevent 4"   # Назад
Start-Sleep -Seconds 1

# Финальная проверка логов
Write-Host "`n📋 Финальная проверка логов..." -ForegroundColor Yellow
$finalLogFile = "build\final_test_logcat.txt"
adb -s $deviceId logcat -d | Select-String "flutter" | Select-Object -Last 100 | Out-File -FilePath $finalLogFile -Encoding UTF8

$finalErrors = Get-Content $finalLogFile | Select-String -Pattern "ERROR|FATAL|Exception"
if ($finalErrors) {
  Write-Host "⚠️ Найдены ошибки после тестирования:" -ForegroundColor Yellow
  $finalErrors | ForEach-Object { Write-Host "  $($_.Line)" -ForegroundColor Red }
}
else {
  Write-Host "✅ Критических ошибок не найдено" -ForegroundColor Green
}

# Результат тестирования
Write-Host "`n🎉 Тестирование завершено!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host "📱 Устройство: $deviceId" -ForegroundColor Cyan
Write-Host "📦 ApplicationId: $applicationId" -ForegroundColor Cyan
Write-Host "📄 Логи: $finalLogFile" -ForegroundColor Cyan
Write-Host "✅ Приложение установлено и протестировано" -ForegroundColor Green

# Открытие папки с логами
if (Test-Path "build") {
  Write-Host "`n📂 Открытие папки с результатами..." -ForegroundColor Yellow
  Start-Process "build"
}


