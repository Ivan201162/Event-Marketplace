# Скрипт для сборки минимальной веб-версии приложения

Write-Host "🔹 Создание минимальной веб-версии приложения..." -ForegroundColor Green

# Создаем резервную копию оригинальных файлов
Write-Host "📁 Создание резервных копий..." -ForegroundColor Yellow
Copy-Item "lib/main.dart" "lib/main_backup.dart" -Force
Copy-Item "pubspec.yaml" "pubspec_backup.yaml" -Force

# Заменяем файлы на минимальные версии
Write-Host "🔄 Замена на минимальные версии..." -ForegroundColor Yellow
Copy-Item "lib/main_minimal.dart" "lib/main.dart" -Force
Copy-Item "pubspec_minimal.yaml" "pubspec.yaml" -Force

# Очищаем проект
Write-Host "🧹 Очистка проекта..." -ForegroundColor Yellow
flutter clean

# Получаем зависимости
Write-Host "📦 Получение зависимостей..." -ForegroundColor Yellow
flutter pub get

# Собираем веб-версию
Write-Host "🌐 Сборка веб-версии..." -ForegroundColor Yellow
flutter build web --release --no-tree-shake-icons

if ($LASTEXITCODE -eq 0) {
  Write-Host "✅ Сборка успешно завершена!" -ForegroundColor Green
  Write-Host "📁 Файлы находятся в папке build/web" -ForegroundColor Green
    
  # Запускаем локальный сервер
  Write-Host "🚀 Запуск локального сервера..." -ForegroundColor Yellow
  Write-Host "Откройте браузер и перейдите по адресу: http://localhost:8080" -ForegroundColor Cyan
    
  # Запускаем простой HTTP сервер
  cd build/web
  python -m http.server 8080
}
else {
  Write-Host "❌ Ошибка сборки!" -ForegroundColor Red
}

# Восстанавливаем оригинальные файлы
Write-Host "🔄 Восстановление оригинальных файлов..." -ForegroundColor Yellow
Copy-Item "lib/main_backup.dart" "lib/main.dart" -Force
Copy-Item "pubspec_backup.yaml" "pubspec.yaml" -Force

# Удаляем временные файлы
Remove-Item "lib/main_backup.dart" -Force
Remove-Item "pubspec_backup.yaml" -Force

Write-Host "🎉 Готово!" -ForegroundColor Green
