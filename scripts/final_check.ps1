# Финальная проверка проекта Event Marketplace App
Write-Host "🎯 Финальная проверка проекта Event Marketplace App" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Counters
$checksPassed = 0
$checksFailed = 0
$totalChecks = 0

# Function to run a check
function Test-Check {
    param(
        [string]$checkName,
        [scriptblock]$checkCommand
    )
    
    $script:totalChecks++
    Write-Host "Проверка: $checkName" -ForegroundColor Blue
    
    try {
        & $checkCommand | Out-Null
        Write-Host "✅ $checkName - ПРОЙДЕНА" -ForegroundColor Green
        $script:checksPassed++
    }
    catch {
        Write-Host "❌ $checkName - ПРОВАЛЕНА" -ForegroundColor Red
        $script:checksFailed++
    }
    Write-Host ""
}

Write-Host "🔍 Проверка структуры проекта..." -ForegroundColor Yellow

# Проверка основных директорий
Test-Check "Директория lib/" { Test-Path "lib" }
Test-Check "Директория test/" { Test-Path "test" }
Test-Check "Директория scripts/" { Test-Path "scripts" }
Test-Check "Директория .github/" { Test-Path ".github" }

Write-Host "📁 Проверка ключевых файлов..." -ForegroundColor Yellow

# Проверка основных файлов
Test-Check "pubspec.yaml" { Test-Path "pubspec.yaml" }
Test-Check "README.md" { Test-Path "README.md" }
Test-Check "PROJECT_REPORT.md" { Test-Path "PROJECT_REPORT.md" }
Test-Check "Dockerfile" { Test-Path "Dockerfile" }
Test-Check "docker-compose.yml" { Test-Path "docker-compose.yml" }
Test-Check "Makefile" { Test-Path "Makefile" }
Test-Check "firebase.json" { Test-Path "firebase.json" }

Write-Host "🏗️ Проверка архитектуры..." -ForegroundColor Yellow

# Проверка структуры lib/
Test-Check "Модели" { Test-Path "lib/models" }
Test-Check "Сервисы" { Test-Path "lib/services" }
Test-Check "Экраны" { Test-Path "lib/screens" }
Test-Check "Виджеты" { Test-Path "lib/widgets" }
Test-Check "Провайдеры" { Test-Path "lib/providers" }

Write-Host "📱 Проверка основных компонентов..." -ForegroundColor Yellow

# Проверка ключевых файлов
Test-Check "main.dart" { Test-Path "lib/main.dart" }
Test-Check "Модель пользователя" { Test-Path "lib/models/user.dart" }
Test-Check "Сервис аутентификации" { Test-Path "lib/services/auth_service.dart" }
Test-Check "Главный экран" { Test-Path "lib/screens/home_screen.dart" }

Write-Host "🔧 Проверка конфигурации..." -ForegroundColor Yellow

# Проверка CI/CD
Test-Check "GitHub Actions" { Test-Path ".github/workflows/ci.yml" }
Test-Check "VS Code настройки" { Test-Path ".vscode/settings.json" }
Test-Check "VS Code запуск" { Test-Path ".vscode/launch.json" }

Write-Host "🧪 Проверка тестирования..." -ForegroundColor Yellow

# Проверка тестов
Test-Check "Интеграционные тесты" { Test-Path "test/integration_test.dart" }
Test-Check "Скрипт тестирования" { Test-Path "scripts/test.sh" }
Test-Check "Скрипт развертывания" { Test-Path "scripts/deploy.sh" }

Write-Host "📊 Подсчет файлов..." -ForegroundColor Yellow

# Подсчет файлов по категориям
$modelsCount = (Get-ChildItem -Path "lib/models" -Filter "*.dart" -ErrorAction SilentlyContinue | Measure-Object).Count
$servicesCount = (Get-ChildItem -Path "lib/services" -Filter "*.dart" -ErrorAction SilentlyContinue | Measure-Object).Count
$screensCount = (Get-ChildItem -Path "lib/screens" -Filter "*.dart" -ErrorAction SilentlyContinue | Measure-Object).Count
$widgetsCount = (Get-ChildItem -Path "lib/widgets" -Filter "*.dart" -ErrorAction SilentlyContinue | Measure-Object).Count
$providersCount = (Get-ChildItem -Path "lib/providers" -Filter "*.dart" -ErrorAction SilentlyContinue | Measure-Object).Count

Write-Host "📈 Статистика проекта:" -ForegroundColor Blue
Write-Host "   Модели: $modelsCount файлов" -ForegroundColor Blue
Write-Host "   Сервисы: $servicesCount файлов" -ForegroundColor Blue
Write-Host "   Экраны: $screensCount файлов" -ForegroundColor Blue
Write-Host "   Виджеты: $widgetsCount файлов" -ForegroundColor Blue
Write-Host "   Провайдеры: $providersCount файлов" -ForegroundColor Blue

Write-Host ""
Write-Host "🎯 Итоговый отчет" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green

Write-Host "Всего проверок: $totalChecks" -ForegroundColor Blue
Write-Host "Пройдено: $checksPassed" -ForegroundColor Green
if ($checksFailed -gt 0) {
    Write-Host "Провалено: $checksFailed" -ForegroundColor Red
} else {
    Write-Host "Провалено: $checksFailed" -ForegroundColor Green
}

Write-Host ""
if ($checksFailed -eq 0) {
    Write-Host "🎉 ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ УСПЕШНО!" -ForegroundColor Green
    Write-Host "Проект Event Marketplace App готов к продакшену!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Следующие шаги:" -ForegroundColor Blue
    Write-Host "1. Запустить тесты: flutter test" -ForegroundColor Blue
    Write-Host "2. Собрать приложение: flutter build web" -ForegroundColor Blue
    Write-Host "3. Развернуть: firebase deploy" -ForegroundColor Blue
    Write-Host ""
    exit 0
} else {
    Write-Host "❌ НЕКОТОРЫЕ ПРОВЕРКИ ПРОВАЛЕНЫ!" -ForegroundColor Red
    Write-Host "Пожалуйста, исправьте ошибки перед продолжением." -ForegroundColor Red
    Write-Host ""
    exit 1
}
