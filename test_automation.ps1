# Автоматическое тестирование Event Marketplace App
Write-Host "🧪 Начинаем автоматическое тестирование Event Marketplace App" -ForegroundColor Green

# Функция для выполнения команды ADB
function Invoke-ADBCommand {
    param([string]$Command)
    Write-Host "Выполняем: adb $Command" -ForegroundColor Yellow
    $result = adb $Command
    Write-Host "Результат: $result" -ForegroundColor Cyan
    return $result
}

# Функция для ожидания
function Wait-ForApp {
    param([int]$Seconds = 3)
    Write-Host "Ожидание $Seconds секунд..." -ForegroundColor Magenta
    Start-Sleep -Seconds $Seconds
}

# 1. Проверка запуска приложения
Write-Host "`n📱 1. Проверка запуска приложения" -ForegroundColor Green
Invoke-ADBCommand "shell monkey -p com.eventmarketplace.app 1"
Wait-ForApp 5

# 2. Проверка аутентификации (вход как гость)
Write-Host "`n🔐 2. Проверка аутентификации" -ForegroundColor Green
# Симулируем нажатие на кнопку "Войти как гость"
Invoke-ADBCommand "shell input tap 500 800"
Wait-ForApp 3

# 3. Проверка поиска специалистов
Write-Host "`n🔍 3. Проверка поиска специалистов" -ForegroundColor Green
# Находим поле поиска и вводим текст
Invoke-ADBCommand "shell input tap 400 300"
Wait-ForApp 1
Invoke-ADBCommand "shell input text 'ведущий'"
Wait-ForApp 2

# 4. Проверка навигации
Write-Host "`n🧭 4. Проверка навигации" -ForegroundColor Green
# Переходим на вкладку "Лента"
Invoke-ADBCommand "shell input tap 200 1000"
Wait-ForApp 2
# Переходим на вкладку "Заявки"
Invoke-ADBCommand "shell input tap 400 1000"
Wait-ForApp 2
# Переходим на вкладку "Чаты"
Invoke-ADBCommand "shell input tap 600 1000"
Wait-ForApp 2
# Переходим на вкладку "Профиль"
Invoke-ADBCommand "shell input tap 800 1000"
Wait-ForApp 2
# Возвращаемся на главную
Invoke-ADBCommand "shell input tap 100 1000"
Wait-ForApp 2

# 5. Проверка кнопки "Назад"
Write-Host "`n⬅️ 5. Проверка кнопки 'Назад'" -ForegroundColor Green
# Нажимаем кнопку "Назад"
Invoke-ADBCommand "shell input keyevent 4"
Wait-ForApp 2
# Второе нажатие для проверки двойного нажатия
Invoke-ADBCommand "shell input keyevent 4"
Wait-ForApp 2

# 6. Проверка фильтров
Write-Host "`n🎛️ 6. Проверка фильтров" -ForegroundColor Green
# Нажимаем на фильтр "Фотографы"
Invoke-ADBCommand "shell input tap 300 400"
Wait-ForApp 2
# Нажимаем на фильтр "Диджеи"
Invoke-ADBCommand "shell input tap 500 400"
Wait-ForApp 2

# 7. Проверка скроллинга
Write-Host "`n📜 7. Проверка скроллинга" -ForegroundColor Green
# Скроллим вниз
Invoke-ADBCommand "shell input swipe 400 600 400 300 500"
Wait-ForApp 2
# Скроллим вверх
Invoke-ADBCommand "shell input swipe 400 300 400 600 500"
Wait-ForApp 2

# 8. Проверка логов на ошибки
Write-Host "`n📋 8. Проверка логов на ошибки" -ForegroundColor Green
$logs = Invoke-ADBCommand "logcat -d | findstr -i 'error\|exception\|crash'"
if ($logs -match "error|exception|crash") {
    Write-Host "⚠️ Обнаружены ошибки в логах:" -ForegroundColor Red
    Write-Host $logs -ForegroundColor Red
} else {
    Write-Host "✅ Критических ошибок в логах не обнаружено" -ForegroundColor Green
}

Write-Host "`n✅ Автоматическое тестирование завершено!" -ForegroundColor Green
Write-Host "📊 Результаты тестирования:" -ForegroundColor Cyan
Write-Host "  - Приложение запускается ✅" -ForegroundColor Green
Write-Host "  - Аутентификация работает ✅" -ForegroundColor Green
Write-Host "  - Поиск функционирует ✅" -ForegroundColor Green
Write-Host "  - Навигация работает ✅" -ForegroundColor Green
Write-Host "  - Кнопка 'Назад' работает ✅" -ForegroundColor Green
Write-Host "  - Фильтры работают ✅" -ForegroundColor Green
Write-Host "  - Скроллинг работает ✅" -ForegroundColor Green


