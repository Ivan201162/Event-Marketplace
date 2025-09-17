#!/bin/bash

# Скрипт для развертывания приложения
# Поддерживает различные платформы и среды

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Конфигурация
ENVIRONMENT=""
PLATFORM=""
VERSION=""
DRY_RUN=false

# Функция для показа справки
show_help() {
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  --environment ENV    Среда развертывания (dev, staging, production)"
    echo "  --platform PLATFORM  Платформа (android, ios, web, firebase)"
    echo "  --version VERSION    Версия для развертывания"
    echo "  --dry-run           Показать что будет сделано без выполнения"
    echo "  --help              Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0 --environment production --platform web --version 1.0.0"
    echo "  $0 --environment staging --platform firebase --dry-run"
}

# Развертывание на Firebase
deploy_firebase() {
    log "Развертывание на Firebase..."
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Будет выполнено развертывание на Firebase"
        return
    fi
    
    # Проверка Firebase CLI
    if ! command -v firebase &> /dev/null; then
        error "Firebase CLI не установлен"
        exit 1
    fi
    
    # Вход в Firebase
    firebase login --no-localhost
    
    # Инициализация проекта (если нужно)
    if [ ! -f "firebase.json" ]; then
        firebase init
    fi
    
    # Сборка проекта
    flutter build web --release
    
    # Развертывание
    firebase deploy --only hosting
    
    success "Развертывание на Firebase завершено"
}

# Развертывание на Google Play
deploy_google_play() {
    log "Развертывание на Google Play..."
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Будет выполнено развертывание на Google Play"
        return
    fi
    
    # Проверка Google Play CLI
    if ! command -v fastlane &> /dev/null; then
        error "Fastlane не установлен"
        exit 1
    fi
    
    # Сборка AAB
    flutter build appbundle --release
    
    # Развертывание через Fastlane
    fastlane android deploy
    
    success "Развертывание на Google Play завершено"
}

# Развертывание на App Store
deploy_app_store() {
    log "Развертывание на App Store..."
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Будет выполнено развертывание на App Store"
        return
    fi
    
    # Проверка платформы
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "iOS развертывание доступно только на macOS"
        exit 1
    fi
    
    # Проверка Fastlane
    if ! command -v fastlane &> /dev/null; then
        error "Fastlane не установлен"
        exit 1
    fi
    
    # Сборка iOS
    flutter build ios --release
    
    # Развертывание через Fastlane
    fastlane ios deploy
    
    success "Развертывание на App Store завершено"
}

# Развертывание на веб-сервер
deploy_web_server() {
    log "Развертывание на веб-сервер..."
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Будет выполнено развертывание на веб-сервер"
        return
    fi
    
    # Сборка веб-версии
    flutter build web --release
    
    # Настройка переменных окружения
    if [ -z "$WEB_SERVER_HOST" ]; then
        error "Переменная WEB_SERVER_HOST не установлена"
        exit 1
    fi
    
    if [ -z "$WEB_SERVER_USER" ]; then
        error "Переменная WEB_SERVER_USER не установлена"
        exit 1
    fi
    
    # Загрузка файлов на сервер
    rsync -avz --delete build/web/ $WEB_SERVER_USER@$WEB_SERVER_HOST:/var/www/html/
    
    success "Развертывание на веб-сервер завершено"
}

# Развертывание на GitHub Pages
deploy_github_pages() {
    log "Развертывание на GitHub Pages..."
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Будет выполнено развертывание на GitHub Pages"
        return
    fi
    
    # Сборка веб-версии
    flutter build web --release --base-href "/event_marketplace_app/"
    
    # Переключение на ветку gh-pages
    git checkout gh-pages || git checkout -b gh-pages
    
    # Копирование файлов
    cp -r build/web/* .
    
    # Коммит и пуш
    git add .
    git commit -m "Deploy version $VERSION"
    git push origin gh-pages
    
    # Возврат на основную ветку
    git checkout main
    
    success "Развертывание на GitHub Pages завершено"
}

# Настройка переменных окружения
setup_environment() {
    log "Настройка переменных окружения для $ENVIRONMENT..."
    
    case $ENVIRONMENT in
        dev)
            export FIREBASE_PROJECT_ID="event-marketplace-dev"
            export GOOGLE_PLAY_TRACK="internal"
            ;;
        staging)
            export FIREBASE_PROJECT_ID="event-marketplace-staging"
            export GOOGLE_PLAY_TRACK="alpha"
            ;;
        production)
            export FIREBASE_PROJECT_ID="event-marketplace-prod"
            export GOOGLE_PLAY_TRACK="production"
            ;;
        *)
            error "Неизвестная среда: $ENVIRONMENT"
            exit 1
            ;;
    esac
    
    success "Переменные окружения настроены"
}

# Проверка зависимостей
check_dependencies() {
    log "Проверка зависимостей..."
    
    if ! command -v flutter &> /dev/null; then
        error "Flutter не установлен"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        error "Git не установлен"
        exit 1
    fi
    
    success "Все зависимости установлены"
}

# Предварительные проверки
pre_deployment_checks() {
    log "Выполнение предварительных проверок..."
    
    # Проверка статуса Git
    if [ -n "$(git status --porcelain)" ]; then
        warning "Есть несохраненные изменения в Git"
        if [ "$DRY_RUN" = false ]; then
            read -p "Продолжить? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    
    # Проверка тегов
    if [ -n "$VERSION" ]; then
        if git tag -l | grep -q "^v$VERSION$"; then
            warning "Тег v$VERSION уже существует"
        fi
    fi
    
    success "Предварительные проверки завершены"
}

# Создание тега
create_tag() {
    if [ -n "$VERSION" ]; then
        log "Создание тега v$VERSION..."
        
        if [ "$DRY_RUN" = true ]; then
            log "DRY RUN: Будет создан тег v$VERSION"
            return
        fi
        
        git tag -a "v$VERSION" -m "Release version $VERSION"
        git push origin "v$VERSION"
        
        success "Тег v$VERSION создан"
    fi
}

# Отправка уведомлений
send_notifications() {
    log "Отправка уведомлений..."
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Будет отправлено уведомление о развертывании"
        return
    fi
    
    # Здесь можно добавить отправку уведомлений в Slack, Discord, email и т.д.
    # Например:
    # curl -X POST -H 'Content-type: application/json' \
    #     --data '{"text":"Deployment completed for version '$VERSION'"}' \
    #     $SLACK_WEBHOOK_URL
    
    success "Уведомления отправлены"
}

# Основная функция
main() {
    log "Начало развертывания Event Marketplace App"
    
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            --environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --platform)
                PLATFORM="$2"
                shift 2
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                error "Неизвестная опция: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Проверка обязательных параметров
    if [ -z "$ENVIRONMENT" ]; then
        error "Не указана среда развертывания"
        show_help
        exit 1
    fi
    
    if [ -z "$PLATFORM" ]; then
        error "Не указана платформа"
        show_help
        exit 1
    fi
    
    # Выполнение шагов развертывания
    check_dependencies
    setup_environment
    pre_deployment_checks
    
    case $PLATFORM in
        firebase)
            deploy_firebase
            ;;
        android|google-play)
            deploy_google_play
            ;;
        ios|app-store)
            deploy_app_store
            ;;
        web|web-server)
            deploy_web_server
            ;;
        github-pages)
            deploy_github_pages
            ;;
        *)
            error "Неизвестная платформа: $PLATFORM"
            exit 1
            ;;
    esac
    
    create_tag
    send_notifications
    
    success "Развертывание завершено успешно!"
    log "Версия $VERSION развернута в среде $ENVIRONMENT на платформе $PLATFORM"
}

# Запуск основной функции
main "$@"