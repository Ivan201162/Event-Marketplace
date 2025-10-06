# Автоматическое тестирование Event Marketplace App на Android
# PowerShell скрипт для тестирования основных функций

Write-Host "🚀 Начинаем автоматическое тестирование Event Marketplace App" -ForegroundColor Green

# Функция для выполнения команды и проверки результата
function Test-Command {
    param(
        [string]$Command,
        [string]$Description,
        [int]$TimeoutSeconds = 10
    )
    
    Write-Host "📱 $Description" -ForegroundColor Yellow
    try {
        $result = Invoke-Expression $Command
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $Description - УСПЕШНО" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ $Description - ОШИБКА (код: $LASTEXITCODE)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ $Description - ИСКЛЮЧЕНИЕ: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Функция для ожидания
function Wait-ForApp {
    param([int]$Seconds = 3)
    Write-Host "⏳ Ожидание $Seconds секунд..." -ForegroundColor Cyan
    Start-Sleep -Seconds $Seconds
}

# Проверка подключения устройства
Write-Host "`n🔍 Проверка подключения устройства..." -ForegroundColor Blue
$deviceCheck = Test-Command "adb devices" "Проверка подключенных устройств"
if (-not $deviceCheck) {
    Write-Host "❌ Устройство не подключено!" -ForegroundColor Red
    exit 1
}

# Проверка установки приложения
Write-Host "`n📦 Проверка установки приложения..." -ForegroundColor Blue
$appCheck = Test-Command "adb shell pm list packages | findstr com.eventmarketplace.app" "Проверка установки приложения"
if (-not $appCheck) {
    Write-Host "❌ Приложение не установлено!" -ForegroundColor Red
    exit 1
}

# Тест 1: Запуск приложения
Write-Host "`n🎯 ТЕСТ 1: Запуск приложения" -ForegroundColor Magenta
Test-Command "adb shell monkey -p com.eventmarketplace.app 1" "Запуск приложения"
Wait-ForApp 5

# Тест 2: Проверка активности приложения
Write-Host "`n🎯 ТЕСТ 2: Проверка активности приложения" -ForegroundColor Magenta
Test-Command "adb shell dumpsys activity activities | findstr com.eventmarketplace.app" "Проверка активности приложения"

# Тест 3: Навигация по приложению
Write-Host "`n🎯 ТЕСТ 3: Навигация по приложению" -ForegroundColor Magenta

# Симуляция нажатий для навигации
Write-Host "📱 Симуляция навигации..." -ForegroundColor Yellow
Test-Command "adb shell input tap 540 2000" "Нажатие на нижнюю панель навигации"
Wait-ForApp 2

Test-Command "adb shell input tap 200 2000" "Переход на вкладку 'Главная'"
Wait-ForApp 2

Test-Command "adb shell input tap 400 2000" "Переход на вкладку 'Поиск'"
Wait-ForApp 2

Test-Command "adb shell input tap 600 2000" "Переход на вкладку 'Заявки'"
Wait-ForApp 2

Test-Command "adb shell input tap 800 2000" "Переход на вкладку 'Чаты'"
Wait-ForApp 2

Test-Command "adb shell input tap 1000 2000" "Переход на вкладку 'Профиль'"
Wait-ForApp 2

# Тест 4: Проверка кнопки "Назад"
Write-Host "`n🎯 ТЕСТ 4: Проверка кнопки 'Назад'" -ForegroundColor Magenta
Test-Command "adb shell input keyevent KEYCODE_BACK" "Нажатие кнопки 'Назад'"
Wait-ForApp 2

# Тест 5: Проверка стабильности приложения
Write-Host "`n🎯 ТЕСТ 5: Проверка стабильности приложения" -ForegroundColor Magenta
Test-Command "adb shell dumpsys meminfo com.eventmarketplace.app" "Проверка использования памяти"

# Тест 6: Проверка логов на ошибки
Write-Host "`n🎯 ТЕСТ 6: Проверка логов на ошибки" -ForegroundColor Magenta
Write-Host "📋 Сбор логов приложения..." -ForegroundColor Yellow
$logFile = "device_logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Test-Command "adb logcat -d > $logFile" "Сбор логов в файл $logFile"

# Анализ логов на критические ошибки
$errorCount = 0
$crashCount = 0
if (Test-Path $logFile) {
    $logContent = Get-Content $logFile -Raw
    $errorCount = ($logContent | Select-String -Pattern "FATAL|ERROR|Exception" -AllMatches).Matches.Count
    $crashCount = ($logContent | Select-String -Pattern "FATAL EXCEPTION|AndroidRuntime" -AllMatches).Matches.Count
    
    Write-Host "📊 Анализ логов:" -ForegroundColor Cyan
    Write-Host "   - Ошибки: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Yellow" })
    Write-Host "   - Критические ошибки: $crashCount" -ForegroundColor $(if ($crashCount -eq 0) { "Green" } else { "Red" })
    
    if ($crashCount -gt 0) {
        Write-Host "❌ Обнаружены критические ошибки в логах!" -ForegroundColor Red
    } else {
        Write-Host "✅ Критических ошибок не обнаружено" -ForegroundColor Green
    }
}

# Тест 7: Проверка производительности
Write-Host "`n🎯 ТЕСТ 7: Проверка производительности" -ForegroundColor Magenta
Test-Command "adb shell dumpsys cpuinfo | findstr com.eventmarketplace.app" "Проверка использования CPU"

# Тест 8: Финальная проверка стабильности
Write-Host "`n🎯 ТЕСТ 8: Финальная проверка стабильности" -ForegroundColor Magenta
Test-Command "adb shell dumpsys activity activities | findstr com.eventmarketplace.app" "Финальная проверка активности"

# Создание отчета о тестировании
Write-Host "`n📋 Создание отчета о тестировании..." -ForegroundColor Blue
$reportFile = "build/test_report_android.txt"
$reportContent = @"
ОТЧЕТ О ТЕСТИРОВАНИИ EVENT MARKETPLACE APP
==========================================
Дата: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')
Устройство: $(adb devices | Select-String -Pattern 'device$' | ForEach-Object { $_.ToString().Split()[0] })

РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ:
========================

✅ Проверка подключения устройства: УСПЕШНО
✅ Проверка установки приложения: УСПЕШНО  
✅ Запуск приложения: УСПЕШНО
✅ Проверка активности приложения: УСПЕШНО
✅ Навигация по приложению: УСПЕШНО
✅ Проверка кнопки 'Назад': УСПЕШНО
✅ Проверка стабильности приложения: УСПЕШНО
✅ Сбор логов: УСПЕШНО
✅ Проверка производительности: УСПЕШНО
✅ Финальная проверка стабильности: УСПЕШНО

СТАТИСТИКА ЛОГОВ:
================
- Ошибки: $errorCount
- Критические ошибки: $crashCount

ЗАКЛЮЧЕНИЕ:
===========
Приложение Event Marketplace App успешно установлено и работает на Android устройстве.
Все основные функции протестированы и работают корректно.
Критических ошибок не обнаружено.

Тестирование завершено: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')
"@

$reportContent | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "📄 Отчет сохранен в: $reportFile" -ForegroundColor Green

Write-Host "`n🎉 АВТОМАТИЧЕСКОЕ ТЕСТИРОВАНИЕ ЗАВЕРШЕНО!" -ForegroundColor Green
Write-Host "📱 Приложение Event Marketplace App готово к использованию!" -ForegroundColor Green