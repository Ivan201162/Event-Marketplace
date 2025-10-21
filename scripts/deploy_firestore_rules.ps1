# Скрипт для развертывания правил Firestore
Write-Host "🚀 Развертывание правил Firestore..." -ForegroundColor Green

# Проверяем, установлен ли Firebase CLI
try {
  $firebaseVersion = firebase --version
  Write-Host "✅ Firebase CLI найден: $firebaseVersion" -ForegroundColor Green
}
catch {
  Write-Host "❌ Firebase CLI не найден. Установите его с помощью: npm install -g firebase-tools" -ForegroundColor Red
  exit 1
}

# Проверяем, авторизованы ли мы в Firebase
try {
  $currentUser = firebase login:list
  if ($currentUser -match "No accounts") {
    Write-Host "⚠️ Не авторизованы в Firebase. Выполняем авторизацию..." -ForegroundColor Yellow
    firebase login
  }
  else {
    Write-Host "✅ Авторизованы в Firebase" -ForegroundColor Green
  }
}
catch {
  Write-Host "❌ Ошибка проверки авторизации Firebase" -ForegroundColor Red
  exit 1
}

# Развертываем правила Firestore
Write-Host "📝 Развертывание правил Firestore..." -ForegroundColor Blue
try {
  firebase deploy --only firestore:rules
  Write-Host "✅ Правила Firestore развернуты успешно!" -ForegroundColor Green
}
catch {
  Write-Host "❌ Ошибка развертывания правил Firestore" -ForegroundColor Red
  exit 1
}

# Развертываем индексы Firestore
Write-Host "📊 Развертывание индексов Firestore..." -ForegroundColor Blue
try {
  firebase deploy --only firestore:indexes
  Write-Host "✅ Индексы Firestore развернуты успешно!" -ForegroundColor Green
}
catch {
  Write-Host "❌ Ошибка развертывания индексов Firestore" -ForegroundColor Red
  exit 1
}

Write-Host "🎉 Развертывание Firestore завершено успешно!" -ForegroundColor Green
Write-Host "Теперь можно тестировать приложение с новыми правилами безопасности." -ForegroundColor Cyan
