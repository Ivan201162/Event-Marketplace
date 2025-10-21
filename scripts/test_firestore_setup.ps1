# Скрипт для тестирования настройки Firestore
Write-Host "🧪 Тестирование настройки Firestore..." -ForegroundColor Green

# Проверяем, что мы в правильной директории
if (-not (Test-Path "pubspec.yaml")) {
  Write-Host "❌ Запустите скрипт из корневой директории проекта" -ForegroundColor Red
  exit 1
}

# Проверяем, что Firebase CLI установлен
try {
  $firebaseVersion = firebase --version
  Write-Host "✅ Firebase CLI найден: $firebaseVersion" -ForegroundColor Green
}
catch {
  Write-Host "❌ Firebase CLI не найден. Установите его с помощью: npm install -g firebase-tools" -ForegroundColor Red
  exit 1
}

# Проверяем конфигурацию Firebase
Write-Host "🔍 Проверка конфигурации Firebase..." -ForegroundColor Blue

if (-not (Test-Path "firebase.json")) {
  Write-Host "❌ Файл firebase.json не найден" -ForegroundColor Red
  exit 1
}

if (-not (Test-Path "firestore.rules")) {
  Write-Host "❌ Файл firestore.rules не найден" -ForegroundColor Red
  exit 1
}

if (-not (Test-Path "firestore.indexes.json")) {
  Write-Host "❌ Файл firestore.indexes.json не найден" -ForegroundColor Red
  exit 1
}

Write-Host "✅ Конфигурационные файлы Firebase найдены" -ForegroundColor Green

# Проверяем синтаксис правил Firestore
Write-Host "📝 Проверка синтаксиса правил Firestore..." -ForegroundColor Blue
try {
  firebase firestore:rules:validate
  Write-Host "✅ Синтаксис правил Firestore корректен" -ForegroundColor Green
}
catch {
  Write-Host "❌ Ошибка в синтаксисе правил Firestore" -ForegroundColor Red
  Write-Host "Исправьте ошибки в файле firestore.rules" -ForegroundColor Yellow
  exit 1
}

# Проверяем синтаксис индексов Firestore
Write-Host "📊 Проверка синтаксиса индексов Firestore..." -ForegroundColor Blue
try {
  firebase firestore:indexes:validate
  Write-Host "✅ Синтаксис индексов Firestore корректен" -ForegroundColor Green
}
catch {
  Write-Host "❌ Ошибка в синтаксисе индексов Firestore" -ForegroundColor Red
  Write-Host "Исправьте ошибки в файле firestore.indexes.json" -ForegroundColor Yellow
  exit 1
}

# Проверяем, что проект Firebase инициализирован
Write-Host "🔧 Проверка инициализации проекта Firebase..." -ForegroundColor Blue
try {
  $firebaseConfig = Get-Content "firebase.json" | ConvertFrom-Json
  if ($firebaseConfig.firestore) {
    Write-Host "✅ Проект Firebase настроен для Firestore" -ForegroundColor Green
  }
  else {
    Write-Host "❌ Firestore не настроен в firebase.json" -ForegroundColor Red
    exit 1
  }
}
catch {
  Write-Host "❌ Ошибка чтения конфигурации Firebase" -ForegroundColor Red
  exit 1
}

Write-Host "🎉 Все проверки пройдены успешно!" -ForegroundColor Green
Write-Host "Теперь можно развернуть правила с помощью: .\scripts\deploy_firestore_rules.ps1" -ForegroundColor Cyan
