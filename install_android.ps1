# Скрипт для установки Event Marketplace на Android устройство
# Запуск: .\install_android.ps1

Write-Host "📱 Установка Event Marketplace на Android устройство" -ForegroundColor Green
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
  Write-Host "`n📋 Инструкции по подключению:" -ForegroundColor Yellow
  Write-Host "1. Включите отладку по USB на Android устройстве" -ForegroundColor White
  Write-Host "2. Подключите устройство к компьютеру через USB" -ForegroundColor White
  Write-Host "3. Разрешите отладку по USB на устройстве" -ForegroundColor White
  Write-Host "4. Запустите скрипт снова" -ForegroundColor White
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

# Проверка существования APK
Write-Host "`n📁 Проверка APK файла..." -ForegroundColor Yellow
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
  $apkSize = (Get-Item $apkPath).Length / 1MB
  Write-Host "✅ APK найден: $apkPath" -ForegroundColor Green
  Write-Host "📊 Размер: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
}
else {
  Write-Host "❌ APK файл не найден. Сначала соберите приложение:" -ForegroundColor Red
  Write-Host "flutter build apk --debug --no-tree-shake-icons" -ForegroundColor White
  exit 1
}

# Удаление старой версии
Write-Host "`n🗑️ Удаление старой версии приложения..." -ForegroundColor Yellow
$uninstallResult = adb -s $deviceId uninstall $applicationId 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "✅ Старая версия удалена" -ForegroundColor Green
}
else {
  Write-Host "ℹ️ Старая версия не найдена (это нормально для первого запуска)" -ForegroundColor Cyan
}

# Установка новой версии
Write-Host "`n📲 Установка новой версии..." -ForegroundColor Yellow
$installResult = adb -s $deviceId install -r $apkPath
if ($LASTEXITCODE -eq 0) {
  Write-Host "✅ Приложение успешно установлено" -ForegroundColor Green
}
else {
  Write-Host "❌ Ошибка установки приложения" -ForegroundColor Red
  Write-Host "Попробуйте:" -ForegroundColor Yellow
  Write-Host "1. Проверить подключение устройства" -ForegroundColor White
  Write-Host "2. Разрешить установку из неизвестных источников" -ForegroundColor White
  Write-Host "3. Освободить место на устройстве" -ForegroundColor White
  exit 1
}

# Запуск приложения
Write-Host "`n🚀 Запуск приложения..." -ForegroundColor Yellow
$launchResult = adb -s $deviceId shell monkey -p $applicationId -c android.intent.category.LAUNCHER 1
if ($LASTEXITCODE -eq 0) {
  Write-Host "✅ Приложение запущено" -ForegroundColor Green
}
else {
  Write-Host "⚠️ Не удалось автоматически запустить приложение" -ForegroundColor Yellow
  Write-Host "Запустите приложение вручную на устройстве" -ForegroundColor White
}

# Ожидание запуска
Write-Host "`n⏳ Ожидание запуска приложения (10 секунд)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Проверка логов
Write-Host "`n📋 Проверка логов приложения..." -ForegroundColor Yellow
$logFile = "build\installation_logcat.txt"
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

# Результат установки
Write-Host "`n🎉 Установка завершена!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host "📱 Устройство: $deviceId" -ForegroundColor Cyan
Write-Host "📦 ApplicationId: $applicationId" -ForegroundColor Cyan
Write-Host "📄 Логи: $logFile" -ForegroundColor Cyan
Write-Host "✅ Приложение установлено и запущено" -ForegroundColor Green

# Открытие папки с логами
if (Test-Path "build") {
  Write-Host "`n📂 Открытие папки с результатами..." -ForegroundColor Yellow
  Start-Process "build"
}

Write-Host "`n🎯 Следующие шаги:" -ForegroundColor Yellow
Write-Host "1. Проверьте работу приложения на устройстве" -ForegroundColor White
Write-Host "2. Настройте Supabase для полного функционала" -ForegroundColor White
Write-Host "3. Протестируйте все функции" -ForegroundColor White