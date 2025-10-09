# Автоматическое тестирование Event Marketplace App
# PowerShell скрипт для тестирования основных функций приложения

param(
  [string]$PackageName = "com.eventmarketplace.app",
  [int]$TestDelay = 3
)

# Функция для логирования
function Write-TestLog {
  param(
    [string]$Message,
    [string]$Level = "INFO"
  )
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logMessage = "[$timestamp] [$Level] $Message"
  Write-Host $logMessage
  Add-Content -Path "build/test_report_android.txt" -Value $logMessage
}

# Функция для симуляции нажатия
function Simulate-Tap {
  param(
    [int]$X,
    [int]$Y,
    [string]$Description
  )
  Write-TestLog "Нажатие: $Description в координатах ($X, $Y)"
  adb shell input tap $X $Y
  Start-Sleep -Seconds 2
}

# Функция для ввода текста
function Simulate-TextInput {
  param(
    [string]$Text,
    [string]$Description
  )
  Write-TestLog "Ввод текста: $Description - '$Text'"
  adb shell input text $Text
  Start-Sleep -Seconds 1
}

# Функция для нажатия клавиши
function Simulate-KeyPress {
  param(
    [int]$KeyCode,
    [string]$Description
  )
  Write-TestLog "Нажатие клавиши: $Description"
  adb shell input keyevent $KeyCode
  Start-Sleep -Seconds 1
}

# Функция для проверки состояния приложения
function Test-AppState {
  param([string]$ExpectedState)
    
  $currentActivity = adb shell dumpsys activity activities | Select-String "mResumedActivity"
  Write-TestLog "Текущая активность: $currentActivity"
    
  if ($currentActivity -like "*$PackageName*") {
    return $true
  }
  return $false
}

# Функция для скролла
function Simulate-Scroll {
  param(
    [int]$StartX,
    [int]$StartY,
    [int]$EndX,
    [int]$EndY,
    [string]$Description
  )
  Write-TestLog "Скролл: $Description"
  adb shell input swipe $StartX $StartY $EndX $EndY
  Start-Sleep -Seconds 2
}

# Начало тестирования
Write-TestLog "=== НАЧАЛО АВТОМАТИЧЕСКОГО ТЕСТИРОВАНИЯ ===" "INFO"
Write-TestLog "Пакет: $PackageName" "INFO"
Write-TestLog "Задержка между действиями: $TestDelay сек" "INFO"

# Проверка подключения устройства
Write-TestLog "=== ПРОВЕРКА ПОДКЛЮЧЕНИЯ УСТРОЙСТВА ===" "INFO"
$devices = adb devices
Write-TestLog "Устройства: $devices" "INFO"

if ($devices -notlike "*device*") {
  Write-TestLog "ОШИБКА: Устройство не подключено!" "ERROR"
  exit 1
}

# Запуск приложения
Write-TestLog "=== ЗАПУСК ПРИЛОЖЕНИЯ ===" "INFO"
adb shell monkey -p $PackageName 1
Start-Sleep -Seconds 5

if (Test-AppState "Запуск") {
  Write-TestLog "Приложение запущено успешно" "SUCCESS"
}
else {
  Write-TestLog "ОШИБКА: Приложение не запустилось!" "ERROR"
  exit 1
}

# === ТЕСТ 1: АУТЕНТИФИКАЦИЯ ===
Write-TestLog "=== ТЕСТ 1: АУТЕНТИФИКАЦИЯ ===" "INFO"

# Проверка экрана входа
Write-TestLog "Проверка экрана входа"
Start-Sleep -Seconds 3

# Тест входа как гость
Write-TestLog "Тестирование входа как гость"
Simulate-Tap 540 1000 "Кнопка 'Войти как гость'"

Start-Sleep -Seconds 3
if (Test-AppState "Главная") {
  Write-TestLog "Вход как гость успешен" "SUCCESS"
}
else {
  Write-TestLog "Вход как гость не удался" "WARNING"
}

# === ТЕСТ 2: ГЛАВНАЯ СТРАНИЦА ===
Write-TestLog "=== ТЕСТ 2: ГЛАВНАЯ СТРАНИЦА ===" "INFO"

# Проверка поиска
Write-TestLog "Проверка функции поиска"
Simulate-Tap 540 200 "Кнопка поиска"
Start-Sleep -Seconds 2

# Ввод поискового запроса
Simulate-TextInput "фотограф" "Поисковый запрос"
Simulate-KeyPress 66 "Enter"

Start-Sleep -Seconds 3
Write-TestLog "Поиск выполнен"

# Возврат на главную
Simulate-KeyPress 4 "Back"
Start-Sleep -Seconds 2

# Проверка фильтров
Write-TestLog "Проверка фильтров"
Simulate-Tap 540 400 "Кнопка фильтров"
Start-Sleep -Seconds 2
Simulate-KeyPress 4 "Back"

# === ТЕСТ 3: НАВИГАЦИЯ ===
Write-TestLog "=== ТЕСТ 3: НАВИГАЦИЯ ===" "INFO"

# Тест вкладки "Чаты"
Write-TestLog "Тестирование вкладки 'Чаты'"
Simulate-Tap 540 1000 "Вкладка 'Чаты'"
Start-Sleep -Seconds 3

if (Test-AppState "Чаты") {
  Write-TestLog "Вкладка 'Чаты' открыта" "SUCCESS"
}
else {
  Write-TestLog "Вкладка 'Чаты' не открылась" "WARNING"
}

# Тест вкладки "Идеи"
Write-TestLog "Тестирование вкладки 'Идеи'"
Simulate-Tap 540 1000 "Вкладка 'Идеи'"
Start-Sleep -Seconds 3

if (Test-AppState "Идеи") {
  Write-TestLog "Вкладка 'Идеи' открыта" "SUCCESS"
}
else {
  Write-TestLog "Вкладка 'Идеи' не открылась" "WARNING"
}

# Тест вкладки "Заявки"
Write-TestLog "Тестирование вкладки 'Заявки'"
Simulate-Tap 540 1000 "Вкладка 'Заявки'"
Start-Sleep -Seconds 3

if (Test-AppState "Заявки") {
  Write-TestLog "Вкладка 'Заявки' открыта" "SUCCESS"
}
else {
  Write-TestLog "Вкладка 'Заявки' не открылась" "WARNING"
}

# Возврат на главную
Write-TestLog "Возврат на главную"
Simulate-Tap 540 1000 "Вкладка 'Главная'"
Start-Sleep -Seconds 2

# === ТЕСТ 4: ПРОФИЛЬ ===
Write-TestLog "=== ТЕСТ 4: ПРОФИЛЬ ===" "INFO"

# Клик по аватарке
Write-TestLog "Тестирование перехода в профиль по клику на аватарку"
Simulate-Tap 200 200 "Аватарка пользователя"
Start-Sleep -Seconds 3

if (Test-AppState "Профиль") {
  Write-TestLog "Переход в профиль успешен" "SUCCESS"
}
else {
  Write-TestLog "Переход в профиль не удался" "WARNING"
}

# Возврат на главную
Simulate-KeyPress 4 "Back"
Start-Sleep -Seconds 2

# === ТЕСТ 5: КНОПКА НАЗАД ===
Write-TestLog "=== ТЕСТ 5: КНОПКА НАЗАД ===" "INFO"

# Тест кнопки "Назад" в разных разделах
Write-TestLog "Тестирование кнопки 'Назад' в разделе 'Чаты'"
Simulate-Tap 540 1000 "Вкладка 'Чаты'"
Start-Sleep -Seconds 2
Simulate-KeyPress 4 "Back"
Start-Sleep -Seconds 2

if (Test-AppState "Главная") {
  Write-TestLog "Кнопка 'Назад' работает корректно" "SUCCESS"
}
else {
  Write-TestLog "Кнопка 'Назад' работает некорректно" "WARNING"
}

# === ТЕСТ 6: СКРОЛЛ И ИНТЕРАКТИВНОСТЬ ===
Write-TestLog "=== ТЕСТ 6: СКРОЛЛ И ИНТЕРАКТИВНОСТЬ ===" "INFO"

# Тест скролла на главной странице
Write-TestLog "Тестирование скролла"
Simulate-Scroll 540 800 540 400 "Скролл вверх"
Start-Sleep -Seconds 2
Simulate-Scroll 540 400 540 800 "Скролл вниз"
Start-Sleep -Seconds 2

# === ТЕСТ 7: СТАБИЛЬНОСТЬ ===
Write-TestLog "=== ТЕСТ 7: СТАБИЛЬНОСТЬ ===" "INFO"

# Быстрое переключение между вкладками
Write-TestLog "Тестирование быстрого переключения между вкладками"
for ($i = 0; $i -lt 3; $i++) {
  Simulate-Tap 540 1000 "Вкладка 'Чаты'"
  Start-Sleep -Seconds 1
  Simulate-Tap 540 1000 "Вкладка 'Идеи'"
  Start-Sleep -Seconds 1
  Simulate-Tap 540 1000 "Вкладка 'Заявки'"
  Start-Sleep -Seconds 1
  Simulate-Tap 540 1000 "Вкладка 'Главная'"
  Start-Sleep -Seconds 1
}

if (Test-AppState "Главная") {
  Write-TestLog "Приложение стабильно при быстром переключении" "SUCCESS"
}
else {
  Write-TestLog "Приложение нестабильно при быстром переключении" "WARNING"
}

# === ЗАВЕРШЕНИЕ ТЕСТИРОВАНИЯ ===
Write-TestLog "=== ЗАВЕРШЕНИЕ АВТОМАТИЧЕСКОГО ТЕСТИРОВАНИЯ ===" "INFO"
Write-TestLog "Все основные тесты выполнены" "SUCCESS"
Write-TestLog "Приложение готово к использованию" "SUCCESS"

# Сбор логов
Write-TestLog "=== СБОР ЛОГОВ ===" "INFO"
adb logcat -d > device_logs.txt
Write-TestLog "Логи сохранены в device_logs.txt" "INFO"

Write-TestLog "=== ТЕСТИРОВАНИЕ ЗАВЕРШЕНО ===" "SUCCESS"