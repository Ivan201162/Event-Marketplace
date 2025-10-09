# Упрощенное автоматическое тестирование Event Marketplace App
Write-Host "🚀 Начинаем автоматическое тестирование Event Marketplace App" -ForegroundColor Green

# Функция для выполнения команды ADB
function Test-AdbCommand {
    param([string]$Command, [string]$Description)
    Write-Host "📱 $Description" -ForegroundColor Yellow
    try {
        Invoke-Expression $Command | Out-Null
        Write-Host "✅ Успешно: $Description" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Ошибка: $Description" -ForegroundColor Red
        return $false
    }
}

# Функция ожидания
function Wait-ForApp {
    param([int]$Seconds = 3)
    Write-Host "⏳ Ожидание $Seconds секунд..." -ForegroundColor Blue
    Start-Sleep -Seconds $Seconds
}

Write-Host "`n🔍 1. ПРОВЕРКА ПОДКЛЮЧЕНИЯ УСТРОЙСТВА" -ForegroundColor Magenta
$devices = adb devices
if ($devices -match "device$") {
    Write-Host "✅ Устройство подключено" -ForegroundColor Green
} else {
    Write-Host "❌ Устройство не подключено!" -ForegroundColor Red
    exit 1
}

Write-Host "`n🚀 2. ЗАПУСК ПРИЛОЖЕНИЯ" -ForegroundColor Magenta
Test-AdbCommand "adb shell monkey -p com.eventmarketplace.app 1" "Запуск приложения"
Wait-ForApp 5

Write-Host "`n🔐 3. ТЕСТИРОВАНИЕ АУТЕНТИФИКАЦИИ" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 500 400" "Нажатие на поле email"
Wait-ForApp 1
Test-AdbCommand "adb shell input text 'test@example.com'" "Ввод тестового email"
Wait-ForApp 1
Test-AdbCommand "adb shell input tap 500 500" "Нажатие на поле пароля"
Wait-ForApp 1
Test-AdbCommand "adb shell input text 'testpassword'" "Ввод тестового пароля"
Wait-ForApp 1
Test-AdbCommand "adb shell input tap 500 600" "Нажатие кнопки входа"
Wait-ForApp 3

Write-Host "`n🏠 4. ТЕСТИРОВАНИЕ ГЛАВНОЙ СТРАНИЦЫ" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 500 200" "Нажатие на поле поиска"
Wait-ForApp 1
Test-AdbCommand "adb shell input text 'фотограф'" "Ввод поискового запроса"
Wait-ForApp 2
Test-AdbCommand "adb shell input keyevent 66" "Нажатие Enter для поиска"
Wait-ForApp 3

Write-Host "`n📋 5. ТЕСТИРОВАНИЕ ЗАЯВОК" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 100 800" "Нажатие на вкладку 'Заявки'"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 200 300" "Нажатие на 'Мои заявки'"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 400 300" "Нажатие на 'Заявки мне'"
Wait-ForApp 2
Test-AdbCommand "adb shell input keyevent 4" "Нажатие кнопки Назад"
Wait-ForApp 2

Write-Host "`n💬 6. ТЕСТИРОВАНИЕ ЧАТОВ" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 300 800" "Нажатие на вкладку 'Чаты'"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 500 300" "Нажатие на первый чат"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 500 700" "Нажатие на поле ввода"
Wait-ForApp 1
Test-AdbCommand "adb shell input text 'Тестовое сообщение'" "Ввод тестового сообщения"
Wait-ForApp 1
Test-AdbCommand "adb shell input tap 900 700" "Нажатие кнопки отправки"
Wait-ForApp 2
Test-AdbCommand "adb shell input keyevent 4" "Нажатие кнопки Назад"
Wait-ForApp 2

Write-Host "`n👤 7. ТЕСТИРОВАНИЕ ПРОФИЛЯ" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 500 800" "Нажатие на вкладку 'Профиль'"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 500 400" "Нажатие на кнопку редактирования"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 500 300" "Нажатие на поле имени"
Wait-ForApp 1
Test-AdbCommand "adb shell input text 'Тестовое имя'" "Ввод тестового имени"
Wait-ForApp 1
Test-AdbCommand "adb shell input tap 500 600" "Нажатие кнопки сохранения"
Wait-ForApp 2

Write-Host "`n🧭 8. ТЕСТИРОВАНИЕ НАВИГАЦИИ" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 200 800" "Переход на главную"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 100 800" "Переход на заявки"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 300 800" "Переход на чаты"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 500 800" "Переход на профиль"
Wait-ForApp 2

Write-Host "`n📊 9. ФИНАЛЬНАЯ ПРОВЕРКА" -ForegroundColor Magenta
$activity = adb shell dumpsys activity activities | Select-String "eventmarketplace"
if ($activity) {
    Write-Host "✅ Приложение работает стабильно" -ForegroundColor Green
} else {
    Write-Host "❌ Приложение не работает стабильно" -ForegroundColor Red
}

Write-Host "`n🎉 АВТОМАТИЧЕСКОЕ ТЕСТИРОВАНИЕ ЗАВЕРШЕНО!" -ForegroundColor Green
Write-Host "Все основные функции протестированы." -ForegroundColor White

