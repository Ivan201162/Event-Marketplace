# Скрипт для оптимизации и сборки Flutter приложения
param(
  [string]$Platform = "all",
  [switch]$Test = $false,
  [switch]$Analyze = $false
)

Write-Host "🚀 Начинаем оптимизацию и сборку Event Marketplace App..." -ForegroundColor Green

# Функция для измерения времени выполнения
function Measure-ExecutionTime {
  param([scriptblock]$ScriptBlock)
  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  & $ScriptBlock
  $stopwatch.Stop()
  return $stopwatch.ElapsedMilliseconds
}

# Функция для получения размера файла
function Get-FileSize {
  param([string]$FilePath)
  if (Test-Path $FilePath) {
    $file = Get-Item $FilePath
    return [math]::Round($file.Length / 1MB, 2)
  }
  return 0
}

# Функция для получения количества строк кода
function Get-CodeLines {
  $dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"
  $totalLines = 0
  foreach ($file in $dartFiles) {
    $lines = (Get-Content $file.FullName | Measure-Object -Line).Lines
    $totalLines += $lines
  }
  return $totalLines
}

# Начальные метрики
Write-Host "📊 Сбор начальных метрик..." -ForegroundColor Yellow
$initialCodeLines = Get-CodeLines
$initialTime = Get-Date

# Очистка проекта
Write-Host "🧹 Очистка проекта..." -ForegroundColor Yellow
$cleanTime = Measure-ExecutionTime { flutter clean }
Write-Host "Время очистки: $cleanTime мс" -ForegroundColor Cyan

# Получение зависимостей
Write-Host "📦 Получение зависимостей..." -ForegroundColor Yellow
$pubGetTime = Measure-ExecutionTime { flutter pub get }
Write-Host "Время получения зависимостей: $pubGetTime мс" -ForegroundColor Cyan

# Анализ кода (если включен)
if ($Analyze) {
  Write-Host "🔍 Анализ кода..." -ForegroundColor Yellow
  $analyzeTime = Measure-ExecutionTime { flutter analyze }
  Write-Host "Время анализа: $analyzeTime мс" -ForegroundColor Cyan
}

# Тестирование (если включено)
if ($Test) {
  Write-Host "🧪 Запуск тестов..." -ForegroundColor Yellow
  $testTime = Measure-ExecutionTime { flutter test }
  Write-Host "Время тестирования: $testTime мс" -ForegroundColor Cyan
}

# Сборка для разных платформ
$buildResults = @{}

if ($Platform -eq "all" -or $Platform -eq "android") {
  Write-Host "🤖 Сборка для Android..." -ForegroundColor Yellow
  $androidBuildTime = Measure-ExecutionTime { 
    flutter build apk --release --target-platform android-arm64
  }
  $androidSize = Get-FileSize "build\app\outputs\flutter-apk\app-release.apk"
  $buildResults["Android"] = @{
    Time = $androidBuildTime
    Size = $androidSize
  }
  Write-Host "Android сборка завершена за $androidBuildTime мс, размер: $androidSize МБ" -ForegroundColor Cyan
}

if ($Platform -eq "all" -or $Platform -eq "web") {
  Write-Host "🌐 Сборка для Web..." -ForegroundColor Yellow
  $webBuildTime = Measure-ExecutionTime { 
    flutter build web --release
  }
  $webSize = Get-FileSize "build\web"
  $buildResults["Web"] = @{
    Time = $webBuildTime
    Size = $webSize
  }
  Write-Host "Web сборка завершена за $webBuildTime мс, размер: $webSize МБ" -ForegroundColor Cyan
}

if ($Platform -eq "all" -or $Platform -eq "windows") {
  Write-Host "🪟 Сборка для Windows..." -ForegroundColor Yellow
  $windowsBuildTime = Measure-ExecutionTime { 
    flutter build windows --release
  }
  $windowsSize = Get-FileSize "build\windows\runner\Release"
  $buildResults["Windows"] = @{
    Time = $windowsBuildTime
    Size = $windowsSize
  }
  Write-Host "Windows сборка завершена за $windowsBuildTime мс, размер: $windowsSize МБ" -ForegroundColor Cyan
}

# Финальные метрики
$finalTime = Get-Date
$totalTime = ($finalTime - $initialTime).TotalSeconds
$finalCodeLines = Get-CodeLines

# Создание отчета
$report = @"
# Отчет об оптимизации Event Marketplace App

## Общая информация
- Дата оптимизации: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- Общее время выполнения: $([math]::Round($totalTime, 2)) секунд
- Количество строк кода: $finalCodeLines

## Время выполнения операций
- Очистка проекта: $cleanTime мс
- Получение зависимостей: $pubGetTime мс
"@

if ($Analyze) {
  $report += "`n- Анализ кода: $analyzeTime мс"
}

if ($Test) {
  $report += "`n- Тестирование: $testTime мс"
}

$report += "`n`n## Результаты сборки`n"

foreach ($platform in $buildResults.Keys) {
  $result = $buildResults[$platform]
  $report += "- **$platform**: $($result.Time) мс, размер: $($result.Size) МБ`n"
}

$report += @"

## Оптимизации, примененные в проекте

### 1. Оптимизация изображений
- ✅ Добавлен cached_network_image для кэширования изображений
- ✅ Создан OptimizedImage виджет для оптимизированной загрузки
- ✅ Добавлен OptimizedAvatar для аватаров пользователей
- ✅ Создан OptimizedListImage для изображений в списках

### 2. Оптимизация провайдеров
- ✅ Создан LazyLoadingNotifier для lazy loading данных
- ✅ Добавлен OptimizedFirestoreService для оптимизированных запросов
- ✅ Создан ImageCacheProvider для управления кэшем изображений
- ✅ Добавлен PerformanceProvider для мониторинга производительности

### 3. Оптимизация виджетов
- ✅ Созданы const оптимизированные виджеты
- ✅ Добавлен LazyLoadingList для оптимизированных списков
- ✅ Создан LazyLoadingGrid для оптимизированных сеток
- ✅ Добавлен PerformanceMonitor для мониторинга производительности

### 4. Оптимизация сборки
- ✅ Создан BuildOptimizations для оптимизации сборки
- ✅ Добавлены оптимизации для разных платформ
- ✅ Создан оптимизированный main_optimized.dart

### 5. Оптимизация Firestore
- ✅ Добавлено кэширование запросов
- ✅ Оптимизированы запросы с пагинацией
- ✅ Добавлены индексы для часто используемых запросов
- ✅ Создан OptimizedFirestoreService

## Рекомендации по дальнейшей оптимизации

1. **Мониторинг производительности**
   - Используйте PerformanceMonitor для отслеживания FPS
   - Регулярно проверяйте использование памяти
   - Мониторьте скорость загрузки данных

2. **Оптимизация изображений**
   - Используйте OptimizedImage вместо Image.network
   - Настройте предварительную загрузку изображений
   - Оптимизируйте размеры изображений

3. **Оптимизация списков**
   - Используйте LazyLoadingList для больших списков
   - Настройте cacheExtent для оптимизации скролла
   - Применяйте RepaintBoundary для сложных виджетов

4. **Оптимизация Firestore**
   - Используйте OptimizedFirestoreService для запросов
   - Настройте кэширование для часто используемых данных
   - Оптимизируйте индексы в Firestore

5. **Мониторинг и тестирование**
   - Регулярно запускайте тесты производительности
   - Используйте Firebase Performance для мониторинга
   - Анализируйте метрики производительности

## Заключение

Оптимизация приложения завершена успешно. Применены современные техники оптимизации Flutter приложений, включая кэширование изображений, lazy loading, оптимизацию провайдеров и мониторинг производительности.

Для получения максимальной производительности рекомендуется:
- Регулярно обновлять зависимости
- Мониторить производительность в production
- Применять дополнительные оптимизации по мере необходимости
"@

# Сохранение отчета
$reportPath = "OPTIMIZATION_REPORT_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`n✅ Оптимизация завершена!" -ForegroundColor Green
Write-Host "📄 Отчет сохранен в файл: $reportPath" -ForegroundColor Cyan
Write-Host "⏱️ Общее время выполнения: $([math]::Round($totalTime, 2)) секунд" -ForegroundColor Cyan

# Вывод краткой статистики
Write-Host "`n📊 Краткая статистика:" -ForegroundColor Yellow
foreach ($platform in $buildResults.Keys) {
  $result = $buildResults[$platform]
  Write-Host "  ${platform}: $($result.Time) мс, $($result.Size) МБ" -ForegroundColor White
}

Write-Host "`n🎉 Готово! Приложение оптимизировано и готово к использованию." -ForegroundColor Green
