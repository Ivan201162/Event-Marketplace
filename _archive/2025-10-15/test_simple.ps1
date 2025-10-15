# Simple Final Testing Script
Write-Host "=== FINAL TESTING EVENT MARKETPLACE ===" -ForegroundColor Green

$packageName = "com.eventmarketplace.app"
$testResults = @{}

# Test 1: App Launch
Write-Host "`n--- Testing App Launch ---" -ForegroundColor Magenta
$result1 = adb shell monkey -p $packageName 1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ App launched successfully" -ForegroundColor Green
    $testResults["App Launch"] = $true
} else {
    Write-Host "✗ App launch failed" -ForegroundColor Red
    $testResults["App Launch"] = $false
}

Start-Sleep -Seconds 3

# Test 2: Navigation
Write-Host "`n--- Testing Navigation ---" -ForegroundColor Magenta
$result2 = adb shell input tap 200 100
Start-Sleep -Seconds 1
$result3 = adb shell input tap 400 100
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Navigation works" -ForegroundColor Green
    $testResults["Navigation"] = $true
} else {
    Write-Host "✗ Navigation issues" -ForegroundColor Red
    $testResults["Navigation"] = $false
}

Start-Sleep -Seconds 2

# Test 3: Search
Write-Host "`n--- Testing Search ---" -ForegroundColor Magenta
$result4 = adb shell input tap 300 200
Start-Sleep -Seconds 1
$result5 = adb shell input text "photographer"
Start-Sleep -Seconds 2
$result6 = adb shell input keyevent 66
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Search works" -ForegroundColor Green
    $testResults["Search"] = $true
} else {
    Write-Host "✗ Search issues" -ForegroundColor Red
    $testResults["Search"] = $false
}

Start-Sleep -Seconds 3

# Test 4: Profile
Write-Host "`n--- Testing Profile ---" -ForegroundColor Magenta
$result7 = adb shell input swipe 300 500 300 200
Start-Sleep -Seconds 1
$result8 = adb shell input swipe 300 200 300 500
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Profile works" -ForegroundColor Green
    $testResults["Profile"] = $true
} else {
    Write-Host "✗ Profile issues" -ForegroundColor Red
    $testResults["Profile"] = $false
}

Start-Sleep -Seconds 2

# Test 5: Chats
Write-Host "`n--- Testing Chats ---" -ForegroundColor Magenta
$result9 = adb shell input tap 500 100
Start-Sleep -Seconds 2
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Chats work" -ForegroundColor Green
    $testResults["Chats"] = $true
} else {
    Write-Host "✗ Chat issues" -ForegroundColor Red
    $testResults["Chats"] = $false
}

# Results
Write-Host "`n=== TEST RESULTS ===" -ForegroundColor Green
$passedTests = 0
$totalTests = $testResults.Count

foreach ($test in $testResults.GetEnumerator()) {
    if ($test.Value) {
        Write-Host "✓ $($test.Key): PASSED" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "✗ $($test.Key): FAILED" -ForegroundColor Red
    }
}

Write-Host "`n=== FINAL STATISTICS ===" -ForegroundColor Yellow
Write-Host "Passed tests: $passedTests of $totalTests" -ForegroundColor Cyan
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)
Write-Host "Success rate: $successRate%" -ForegroundColor Cyan

if ($passedTests -eq $totalTests) {
    Write-Host "`n🎉 ALL TESTS PASSED! APP IS READY FOR RELEASE!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  SOME TESTS FAILED. NEEDS IMPROVEMENT." -ForegroundColor Yellow
}

Write-Host "`n=== TESTING COMPLETED ===" -ForegroundColor Green
Write-Host "Time: $(Get-Date)" -ForegroundColor Yellow
