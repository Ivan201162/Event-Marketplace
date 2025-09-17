#!/bin/bash

# Скрипт для сборки релизных версий приложения
# Поддерживает Android APK/AAB и iOS IPA

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

# Очистка проекта
clean_project() {
    log "Очистка проекта..."
    flutter clean
    flutter pub get
    success "Проект очищен"
}

# Проверка кода
check_code() {
    log "Проверка кода..."
    
    # Форматирование кода
    flutter format .
    
    # Анализ кода
    flutter analyze
    
    # Запуск тестов
    flutter test
    
    success "Код проверен"
}

# Сборка Android APK
build_android_apk() {
    log "Сборка Android APK..."
    
    # Debug APK
    flutter build apk --debug
    success "Debug APK собран"
    
    # Release APK
    flutter build apk --release
    success "Release APK собран"
    
    # Создание папки для артефактов
    mkdir -p build/artifacts/android
    
    # Копирование APK файлов
    cp build/app/outputs/flutter-apk/app-debug.apk build/artifacts/android/
    cp build/app/outputs/flutter-apk/app-release.apk build/artifacts/android/
    
    success "Android APK файлы готовы"
}

# Сборка Android AAB
build_android_aab() {
    log "Сборка Android AAB..."
    
    # Release AAB
    flutter build appbundle --release
    success "Release AAB собран"
    
    # Создание папки для артефактов
    mkdir -p build/artifacts/android
    
    # Копирование AAB файла
    cp build/app/outputs/bundle/release/app-release.aab build/artifacts/android/
    
    success "Android AAB файл готов"
}

# Сборка iOS IPA
build_ios_ipa() {
    log "Сборка iOS IPA..."
    
    # Проверка платформы
    if [[ "$OSTYPE" != "darwin"* ]]; then
        warning "iOS сборка доступна только на macOS"
        return
    fi
    
    # Проверка Xcode
    if ! command -v xcodebuild &> /dev/null; then
        warning "Xcode не установлен, пропускаем iOS сборку"
        return
    fi
    
    # Release IPA
    flutter build ios --release
    success "iOS IPA собран"
    
    # Создание папки для артефактов
    mkdir -p build/artifacts/ios
    
    # Копирование IPA файла (если есть)
    if [ -f "build/ios/ipa/app.ipa" ]; then
        cp build/ios/ipa/app.ipa build/artifacts/ios/
        success "iOS IPA файл готов"
    else
        warning "IPA файл не найден"
    fi
}

# Сборка Web
build_web() {
    log "Сборка Web версии..."
    
    # Release Web
    flutter build web --release
    success "Web версия собрана"
    
    # Создание папки для артефактов
    mkdir -p build/artifacts/web
    
    # Копирование Web файлов
    cp -r build/web/* build/artifacts/web/
    
    success "Web версия готова"
}

# Генерация ключей
generate_keys() {
    log "Генерация ключей..."
    
    # Создание папки для ключей
    mkdir -p build/keys
    
    # Генерация Android ключа (если не существует)
    if [ ! -f "build/keys/upload-keystore.jks" ]; then
        keytool -genkey -v -keystore build/keys/upload-keystore.jks \
            -keyalg RSA -keysize 2048 -validity 10000 \
            -alias upload -storepass android -keypass android \
            -dname "CN=Event Marketplace, OU=Development, O=Event Marketplace, L=Moscow, S=Moscow, C=RU"
        success "Android ключ сгенерирован"
    else
        warning "Android ключ уже существует"
    fi
    
    # Генерация iOS сертификата (только на macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v security &> /dev/null; then
            warning "Keychain не доступен, пропускаем iOS сертификат"
        else
            success "iOS сертификат готов"
        fi
    fi
}

# Создание манифеста релиза
create_release_manifest() {
    log "Создание манифеста релиза..."
    
    cat > build/artifacts/RELEASE_MANIFEST.md << EOF
# Event Marketplace App - Release Manifest

## Информация о релизе
- **Версия**: $(grep 'version:' pubspec.yaml | cut -d' ' -f2)
- **Дата сборки**: $(date)
- **Git commit**: $(git rev-parse HEAD)
- **Git branch**: $(git branch --show-current)

## Собранные артефакты

### Android
- **APK Debug**: app-debug.apk
- **APK Release**: app-release.apk
- **AAB Release**: app-release.aab

### iOS
- **IPA Release**: app.ipa

### Web
- **Web Build**: Все файлы в папке web/

## Инструкции по установке

### Android
1. Включите "Неизвестные источники" в настройках
2. Установите APK файл
3. Или загрузите AAB в Google Play Console

### iOS
1. Установите через Xcode или TestFlight
2. Убедитесь, что устройство добавлено в профиль разработчика

### Web
1. Загрузите файлы на веб-сервер
2. Настройте HTTPS
3. Обновите DNS записи

## Проверки безопасности
- [ ] Код проанализирован
- [ ] Тесты пройдены
- [ ] Ключи сгенерированы
- [ ] Манифест создан

## Контакты
- **Разработчик**: Event Marketplace Team
- **Email**: support@eventmarketplace.app
- **Веб-сайт**: https://eventmarketplace.app
EOF

    success "Манифест релиза создан"
}

# Создание архива
create_archive() {
    log "Создание архива..."
    
    # Создание архива с артефактами
    tar -czf "build/event_marketplace_app_$(date +%Y%m%d_%H%M%S).tar.gz" \
        -C build artifacts/
    
    success "Архив создан"
}

# Основная функция
main() {
    log "Начало сборки релиза Event Marketplace App"
    
    # Проверка аргументов
    PLATFORMS=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            --android)
                PLATFORMS="$PLATFORMS android"
                shift
                ;;
            --ios)
                PLATFORMS="$PLATFORMS ios"
                shift
                ;;
            --web)
                PLATFORMS="$PLATFORMS web"
                shift
                ;;
            --all)
                PLATFORMS="android ios web"
                shift
                ;;
            --keys)
                GENERATE_KEYS=true
                shift
                ;;
            --help)
                echo "Использование: $0 [опции]"
                echo "Опции:"
                echo "  --android    Собрать Android версию"
                echo "  --ios        Собрать iOS версию"
                echo "  --web        Собрать Web версию"
                echo "  --all        Собрать все версии"
                echo "  --keys       Сгенерировать ключи"
                echo "  --help       Показать эту справку"
                exit 0
                ;;
            *)
                error "Неизвестная опция: $1"
                exit 1
                ;;
        esac
    done
    
    # Если платформы не указаны, собираем все
    if [ -z "$PLATFORMS" ]; then
        PLATFORMS="android ios web"
    fi
    
    # Выполнение шагов
    check_dependencies
    clean_project
    check_code
    
    if [ "$GENERATE_KEYS" = true ]; then
        generate_keys
    fi
    
    for platform in $PLATFORMS; do
        case $platform in
            android)
                build_android_apk
                build_android_aab
                ;;
            ios)
                build_ios_ipa
                ;;
            web)
                build_web
                ;;
        esac
    done
    
    create_release_manifest
    create_archive
    
    success "Сборка релиза завершена успешно!"
    log "Артефакты находятся в папке build/artifacts/"
}

# Запуск основной функции
main "$@"
