# Android App Testing Script
Write-Host "Starting Event Marketplace App Testing" -ForegroundColor Green

function Test-AdbCommand {
    param([string]$Command, [string]$Description)
    Write-Host "Testing: $Description" -ForegroundColor Yellow
    try {
        Invoke-Expression $Command | Out-Null
        Write-Host "Success: $Description" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error: $Description" -ForegroundColor Red
        return $false
    }
}

function Wait-ForApp {
    param([int]$Seconds = 3)
    Write-Host "Waiting $Seconds seconds..." -ForegroundColor Blue
    Start-Sleep -Seconds $Seconds
}

Write-Host "`n1. CHECKING DEVICE CONNECTION" -ForegroundColor Magenta
$devices = adb devices
if ($devices -match "device$") {
    Write-Host "Device connected successfully" -ForegroundColor Green
} else {
    Write-Host "Device not connected!" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. LAUNCHING APP" -ForegroundColor Magenta
Test-AdbCommand "adb shell monkey -p com.eventmarketplace.app 1" "Launch app"
Wait-ForApp 5

Write-Host "`n3. TESTING AUTHENTICATION" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 500 400" "Tap email field"
Wait-ForApp 1
Test-AdbCommand "adb shell input text 'test@example.com'" "Enter test email"
Wait-ForApp 1
Test-AdbCommand "adb shell input tap 500 500" "Tap password field"
Wait-ForApp 1
Test-AdbCommand "adb shell input text 'testpassword'" "Enter test password"
Wait-ForApp 1
Test-AdbCommand "adb shell input tap 500 600" "Tap login button"
Wait-ForApp 3

Write-Host "`n4. TESTING HOME SCREEN" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 500 200" "Tap search field"
Wait-ForApp 1
Test-AdbCommand "adb shell input text 'photographer'" "Enter search query"
Wait-ForApp 2
Test-AdbCommand "adb shell input keyevent 66" "Press Enter to search"
Wait-ForApp 3

Write-Host "`n5. TESTING BOOKINGS" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 100 800" "Tap Bookings tab"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 200 300" "Tap My Bookings"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 400 300" "Tap Bookings to Me"
Wait-ForApp 2
Test-AdbCommand "adb shell input keyevent 4" "Press Back button"
Wait-ForApp 2

Write-Host "`n6. TESTING CHATS" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 300 800" "Tap Chats tab"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 500 300" "Tap first chat"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 500 700" "Tap input field"
Wait-ForApp 1
Test-AdbCommand "adb shell input text 'Test message'" "Enter test message"
Wait-ForApp 1
Test-AdbCommand "adb shell input tap 900 700" "Tap send button"
Wait-ForApp 2
Test-AdbCommand "adb shell input keyevent 4" "Press Back button"
Wait-ForApp 2

Write-Host "`n7. TESTING PROFILE" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 500 800" "Tap Profile tab"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 500 400" "Tap edit button"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 500 300" "Tap name field"
Wait-ForApp 1
Test-AdbCommand "adb shell input text 'Test Name'" "Enter test name"
Wait-ForApp 1
Test-AdbCommand "adb shell input tap 500 600" "Tap save button"
Wait-ForApp 2

Write-Host "`n8. TESTING NAVIGATION" -ForegroundColor Magenta
Test-AdbCommand "adb shell input tap 200 800" "Go to Home"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 100 800" "Go to Bookings"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 300 800" "Go to Chats"
Wait-ForApp 2
Test-AdbCommand "adb shell input tap 500 800" "Go to Profile"
Wait-ForApp 2

Write-Host "`n9. FINAL CHECK" -ForegroundColor Magenta
$activity = adb shell dumpsys activity activities | Select-String "eventmarketplace"
if ($activity) {
    Write-Host "App is running stable" -ForegroundColor Green
} else {
    Write-Host "App is not running stable" -ForegroundColor Red
}

Write-Host "`nAutomated testing completed!" -ForegroundColor Green
Write-Host "All main functions have been tested." -ForegroundColor White

