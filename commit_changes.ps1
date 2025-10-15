# Скрипт для сохранения изменений в Git
# Event Marketplace App - Commit Changes Script

Write-Host "📝 Event Marketplace App - Сохранение изменений" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Проверяем статус Git
Write-Host "🔍 Проверка статуса Git..." -ForegroundColor Cyan
$gitStatus = git status --porcelain

if (-not $gitStatus) {
    Write-Host "ℹ️  Нет изменений для коммита" -ForegroundColor Yellow
    exit 0
}

Write-Host "📋 Найденные изменения:" -ForegroundColor Yellow
git status --short

# Добавляем все изменения
Write-Host "`n📦 Добавление изменений в индекс..." -ForegroundColor Cyan
git add .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при добавлении файлов" -ForegroundColor Red
    exit 1
}

# Создаем коммит
Write-Host "💾 Создание коммита..." -ForegroundColor Cyan
$commitMessage = "✨ Обновление: фильтры, заявки, идеи, редактирование профиля, улучшение аутентификации

🧭 Главный экран (HomeScreen):
- ✅ Исправлена работа фильтров с модальным окном
- ✅ Добавлены фильтры: город, категория, рейтинг, тип специалиста
- ✅ Удален блок быстрых действий

📩 Заявки (RequestsScreen):
- ✅ Добавлены вкладки: 'Мои заявки' и 'Заявки мне'
- ✅ Реализована фильтрация по created_by и assigned_to

📸 Идеи (IdeasScreen):
- ✅ Добавлен FloatingActionButton для создания публикаций
- ✅ Расширена форма: пост, фото, видео, рилс
- ✅ Улучшена загрузка медиа

👤 Профиль (ProfileScreen):
- ✅ Добавлена кнопка редактирования профиля
- ✅ Реализовано изменение: имя, город, статус, описание, навыки, аватар
- ✅ Интеграция с Firebase Auth

📲 Аутентификация (AuthScreen):
- ✅ Сделана вкладка входа по телефону видимой
- ✅ Добавлены переключатели способов входа
- ✅ Улучшен UI для мобильных устройств"

git commit -m $commitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при создании коммита" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Коммит успешно создан!" -ForegroundColor Green

# Создаем тег
Write-Host "🏷️  Создание тега версии..." -ForegroundColor Cyan
git tag -a v1.1-stable -m "Stable build after UI improvements"

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Ошибка при создании тега (возможно, тег уже существует)" -ForegroundColor Yellow
} else {
    Write-Host "✅ Тег v1.1-stable создан!" -ForegroundColor Green
}

# Показываем информацию о коммите
Write-Host "`n📊 Информация о коммите:" -ForegroundColor Yellow
git log --oneline -1

Write-Host "`n🎉 Изменения успешно сохранены!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Опционально: отправка в удаленный репозиторий
$pushToRemote = Read-Host "`n🚀 Отправить изменения в удаленный репозиторий? (y/N)"
if ($pushToRemote -eq "y" -or $pushToRemote -eq "Y") {
    Write-Host "📤 Отправка в удаленный репозиторий..." -ForegroundColor Cyan
    git push origin main --tags
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Изменения отправлены в удаленный репозиторий!" -ForegroundColor Green
    } else {
        Write-Host "❌ Ошибка при отправке в удаленный репозиторий" -ForegroundColor Red
    }
}

Write-Host "`n💡 Следующие шаги:" -ForegroundColor Cyan
Write-Host "   1. Запустите build_and_install.ps1 для установки на устройство" -ForegroundColor White
Write-Host "   2. Протестируйте все новые функции" -ForegroundColor White
Write-Host "   3. При необходимости создайте дополнительные коммиты" -ForegroundColor White
