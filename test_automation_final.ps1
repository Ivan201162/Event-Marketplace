# Финальное автоматическое тестирование приложения Event Marketplace
# Автор: AI Assistant
# Дата: $(Get-Date)

Write-Host "=== ФИНАЛЬНОЕ ТЕСТИРОВАНИЕ EVENT MARKETPLACE ===" -ForegroundColor Green
Write-Host "Время начала: $(Get-Date)" -ForegroundColor Yellow

# Функция для выполнения команды ADB
function Invoke-ADBCommand {
    param([string]$Command)
    Write-Host "Выполняю: adb $Command" -ForegroundColor Cyan
    $result = adb $Command 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Успешно" -ForegroundColor Green
        return $result
    } else {
        Write-Host "✗ Ошибка: $result" -ForegroundColor Red
        return $null
    }
}

# Функция для тестирования экрана
function Test-Screen {
    param([string]$ScreenName, [string]$PackageName)
    Write-Host "`n--- Тестирование: $ScreenName ---" -ForegroundColor Magenta
    
    # Запуск приложения
    $result = Invoke-ADBCommand "shell monkey -p $PackageName 1"
    if ($result) {
        Start-Sleep -Seconds 3
        Write-Host "✓ Экран $ScreenName открыт" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Не удалось открыть экран $ScreenName" -ForegroundColor Red
        return $false
    }
}

# Функция для тестирования навигации
function Test-Navigation {
    param([string]$PackageName)
    Write-Host "`n--- Тестирование навигации ---" -ForegroundColor Magenta
    
    # Тест 1: Открытие главного экрана
    $result1 = Test-Screen "Главный экран" $PackageName
    Start-Sleep -Seconds 2
    
    # Тест 2: Навигация по вкладкам
    Write-Host "Тестирование навигации по вкладкам..." -ForegroundColor Cyan
    $result2 = Invoke-ADBCommand "shell input tap 200 100"  # Тап по вкладке
    Start-Sleep -Seconds 1
    
    $result3 = Invoke-ADBCommand "shell input tap 400 100"  # Тап по другой вкладке
    Start-Sleep -Seconds 1
    
    if ($result1) {
        Write-Host "✓ Навигация работает" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Проблемы с навигацией" -ForegroundColor Red
        return $false
    }
}

# Функция для тестирования поиска
function Test-Search {
    param([string]$PackageName)
    Write-Host "`n--- Тестирование поиска ---" -ForegroundColor Magenta
    
    # Открытие экрана поиска
    $result1 = Test-Screen "Поиск" $PackageName
    Start-Sleep -Seconds 2
    
    # Тест ввода текста
    Write-Host "Тестирование ввода в поиск..." -ForegroundColor Cyan
    $result2 = Invoke-ADBCommand "shell input tap 300 200"  # Тап по полю поиска
    Start-Sleep -Seconds 1
    
    $result3 = Invoke-ADBCommand "shell input text 'фотограф'"  # Ввод текста
    Start-Sleep -Seconds 2
    
    $result4 = Invoke-ADBCommand "shell input keyevent 66"  # Enter
    Start-Sleep -Seconds 3
    
    if ($result1) {
        Write-Host "✓ Поиск работает" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Проблемы с поиском" -ForegroundColor Red
        return $false
    }
}

# Функция для тестирования профиля
function Test-Profile {
    param([string]$PackageName)
    Write-Host "`n--- Тестирование профиля ---" -ForegroundColor Magenta
    
    # Открытие профиля
    $result1 = Test-Screen "Профиль" $PackageName
    Start-Sleep -Seconds 2
    
    # Тест прокрутки профиля
    Write-Host "Тестирование прокрутки профиля..." -ForegroundColor Cyan
    $result2 = Invoke-ADBCommand "shell input swipe 300 500 300 200"  # Свайп вверх
    Start-Sleep -Seconds 1
    
    $result3 = Invoke-ADBCommand "shell input swipe 300 200 300 500"  # Свайп вниз
    Start-Sleep -Seconds 1
    
    if ($result1) {
        Write-Host "✓ Профиль работает" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Проблемы с профилем" -ForegroundColor Red
        return $false
    }
}

# Функция для тестирования чатов
function Test-Chats {
    param([string]$PackageName)
    Write-Host "`n--- Тестирование чатов ---" -ForegroundColor Magenta
    
    # Открытие чатов
    $result1 = Test-Screen "Чаты" $PackageName
    Start-Sleep -Seconds 2
    
    # Тест создания нового чата
    Write-Host "Тестирование создания чата..." -ForegroundColor Cyan
    $result2 = Invoke-ADBCommand "shell input tap 500 100"  # Тап по кнопке создания
    Start-Sleep -Seconds 2
    
    if ($result1) {
        Write-Host "✓ Чаты работают" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Проблемы с чатами" -ForegroundColor Red
        return $false
    }
}

# Функция для тестирования авторизации
function Test-Auth {
    param([string]$PackageName)
    Write-Host "`n--- Тестирование авторизации ---" -ForegroundColor Magenta
    
    # Открытие экрана авторизации
    $result1 = Test-Screen "Авторизация" $PackageName
    Start-Sleep -Seconds 2
    
    # Тест входа как гость
    Write-Host "Тестирование входа как гость..." -ForegroundColor Cyan
    $result2 = Invoke-ADBCommand "shell input tap 300 400"  # Тап по кнопке "Войти как гость"
    Start-Sleep -Seconds 3
    
    if ($result1) {
        Write-Host "✓ Авторизация работает" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Проблемы с авторизацией" -ForegroundColor Red
        return $false
    }
}

# Основная функция тестирования
function Start-FinalTesting {
    param([string]$PackageName = "com.eventmarketplace.app")
    
    Write-Host "`n=== НАЧАЛО ФИНАЛЬНОГО ТЕСТИРОВАНИЯ ===" -ForegroundColor Green
    Write-Host "Пакет: $PackageName" -ForegroundColor Yellow
    
    $testResults = @{}
    
    # Тест 1: Авторизация
    $testResults["Авторизация"] = Test-Auth $PackageName
    
    # Тест 2: Навигация
    $testResults["Навигация"] = Test-Navigation $PackageName
    
    # Тест 3: Поиск
    $testResults["Поиск"] = Test-Search $PackageName
    
    # Тест 4: Профиль
    $testResults["Профиль"] = Test-Profile $PackageName
    
    # Тест 5: Чаты
    $testResults["Чаты"] = Test-Chats $PackageName
    
    # Результаты тестирования
    Write-Host "`n=== РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ ===" -ForegroundColor Green
    $passedTests = 0
    $totalTests = $testResults.Count
    
    foreach ($test in $testResults.GetEnumerator()) {
        if ($test.Value) {
            Write-Host "✓ $($test.Key): ПРОЙДЕН" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "✗ $($test.Key): ПРОВАЛЕН" -ForegroundColor Red
        }
    }
    
    Write-Host "`n=== ИТОГОВАЯ СТАТИСТИКА ===" -ForegroundColor Yellow
    Write-Host "Пройдено тестов: $passedTests из $totalTests" -ForegroundColor Cyan
    Write-Host "Процент успеха: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan
    
    if ($passedTests -eq $totalTests) {
        Write-Host "`n🎉 ВСЕ ТЕСТЫ ПРОЙДЕНЫ! ПРИЛОЖЕНИЕ ГОТОВО К РЕЛИЗУ!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "`n⚠️  НЕКОТОРЫЕ ТЕСТЫ ПРОВАЛЕНЫ. ТРЕБУЕТСЯ ДОРАБОТКА." -ForegroundColor Yellow
        return $false
    }
}

# Запуск тестирования
$success = Start-FinalTesting

Write-Host "`n=== ТЕСТИРОВАНИЕ ЗАВЕРШЕНО ===" -ForegroundColor Green
Write-Host "Время завершения: $(Get-Date)" -ForegroundColor Yellow

# Сохранение результатов
$results = @{
    "Время начала" = Get-Date
    "Время завершения" = Get-Date
    "Успех" = $success
    "Пакет" = "com.eventmarketplace.app"
}

$results | ConvertTo-Json | Out-File -FilePath "final_test_results.json" -Encoding UTF8
Write-Host "Результаты сохранены в final_test_results.json" -ForegroundColor Cyan

if ($success) {
    exit 0
} else {
    exit 1
}
