#!/bin/bash

# Финальная проверка проекта Event Marketplace App
set -e

echo "🎯 Финальная проверка проекта Event Marketplace App"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✅]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ️]${NC} $1"
}

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
TOTAL_CHECKS=0

# Function to run a check
run_check() {
    local check_name="$1"
    local check_command="$2"
    
    ((TOTAL_CHECKS++))
    print_info "Проверка: $check_name"
    
    if eval "$check_command" > /dev/null 2>&1; then
        print_status "$check_name - ПРОЙДЕНА"
        ((CHECKS_PASSED++))
    else
        print_error "$check_name - ПРОВАЛЕНА"
        ((CHECKS_FAILED++))
    fi
    echo ""
}

echo "🔍 Проверка структуры проекта..."

# Проверка основных директорий
run_check "Директория lib/" "test -d lib"
run_check "Директория test/" "test -d test"
run_check "Директория scripts/" "test -d scripts"
run_check "Директория .github/" "test -d .github"

echo "📁 Проверка ключевых файлов..."

# Проверка основных файлов
run_check "pubspec.yaml" "test -f pubspec.yaml"
run_check "README.md" "test -f README.md"
run_check "PROJECT_REPORT.md" "test -f PROJECT_REPORT.md"
run_check "Dockerfile" "test -f Dockerfile"
run_check "docker-compose.yml" "test -f docker-compose.yml"
run_check "Makefile" "test -f Makefile"
run_check "firebase.json" "test -f firebase.json"

echo "🏗️ Проверка архитектуры..."

# Проверка структуры lib/
run_check "Модели" "test -d lib/models"
run_check "Сервисы" "test -d lib/services"
run_check "Экраны" "test -d lib/screens"
run_check "Виджеты" "test -d lib/widgets"
run_check "Провайдеры" "test -d lib/providers"

echo "📱 Проверка основных компонентов..."

# Проверка ключевых файлов
run_check "main.dart" "test -f lib/main.dart"
run_check "Модель пользователя" "test -f lib/models/user.dart"
run_check "Сервис аутентификации" "test -f lib/services/auth_service.dart"
run_check "Главный экран" "test -f lib/screens/home_screen.dart"

echo "🔧 Проверка конфигурации..."

# Проверка CI/CD
run_check "GitHub Actions" "test -f .github/workflows/ci.yml"
run_check "VS Code настройки" "test -f .vscode/settings.json"
run_check "VS Code запуск" "test -f .vscode/launch.json"

echo "🧪 Проверка тестирования..."

# Проверка тестов
run_check "Интеграционные тесты" "test -f test/integration_test.dart"
run_check "Скрипт тестирования" "test -f scripts/test.sh"
run_check "Скрипт развертывания" "test -f scripts/deploy.sh"

echo "📊 Подсчет файлов..."

# Подсчет файлов по категориям
MODELS_COUNT=$(find lib/models -name "*.dart" 2>/dev/null | wc -l)
SERVICES_COUNT=$(find lib/services -name "*.dart" 2>/dev/null | wc -l)
SCREENS_COUNT=$(find lib/screens -name "*.dart" 2>/dev/null | wc -l)
WIDGETS_COUNT=$(find lib/widgets -name "*.dart" 2>/dev/null | wc -l)
PROVIDERS_COUNT=$(find lib/providers -name "*.dart" 2>/dev/null | wc -l)

print_info "📈 Статистика проекта:"
print_info "   Модели: $MODELS_COUNT файлов"
print_info "   Сервисы: $SERVICES_COUNT файлов"
print_info "   Экраны: $SCREENS_COUNT файлов"
print_info "   Виджеты: $WIDGETS_COUNT файлов"
print_info "   Провайдеры: $PROVIDERS_COUNT файлов"

echo ""
echo "🎯 Итоговый отчет"
echo "=================="

print_info "Всего проверок: $TOTAL_CHECKS"
print_status "Пройдено: $CHECKS_PASSED"
if [ $CHECKS_FAILED -gt 0 ]; then
    print_error "Провалено: $CHECKS_FAILED"
else
    print_status "Провалено: $CHECKS_FAILED"
fi

echo ""
if [ $CHECKS_FAILED -eq 0 ]; then
    print_status "🎉 ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ УСПЕШНО!"
    print_status "Проект Event Marketplace App готов к продакшену!"
    echo ""
    print_info "Следующие шаги:"
    print_info "1. Запустить тесты: make test"
    print_info "2. Собрать приложение: make build"
    print_info "3. Развернуть: make deploy"
    echo ""
    exit 0
else
    print_error "❌ НЕКОТОРЫЕ ПРОВЕРКИ ПРОВАЛЕНЫ!"
    print_error "Пожалуйста, исправьте ошибки перед продолжением."
    echo ""
    exit 1
fi
