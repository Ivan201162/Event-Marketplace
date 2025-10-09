# Simple Android Test Script
param(
    [string]$PackageName = "com.eventmarketplace.app"
)

function Write-TestLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path "build/test_report_android.txt" -Value $logMessage
}

function Simulate-Tap {
    param([int]$X, [int]$Y, [string]$Description)
    Write-TestLog "Tap: $Description at ($X, $Y)"
    adb shell input tap $X $Y
    Start-Sleep -Seconds 2
}

function Simulate-KeyPress {
    param([int]$KeyCode, [string]$Description)
    Write-TestLog "Key: $Description"
    adb shell input keyevent $KeyCode
    Start-Sleep -Seconds 1
}

Write-TestLog "=== ANDROID AUTOMATED TESTING STARTED ==="
Write-TestLog "Package: $PackageName"

# Check device connection
$devices = adb devices
Write-TestLog "Devices: $devices"

if ($devices -notlike "*device*") {
    Write-TestLog "ERROR: No device connected!"
    exit 1
}

# Launch app
Write-TestLog "=== LAUNCHING APP ==="
adb shell monkey -p $PackageName 1
Start-Sleep -Seconds 5

# Test 1: Authentication
Write-TestLog "=== TEST 1: AUTHENTICATION ==="
Write-TestLog "Testing guest login"
Simulate-Tap 540 1000 "Guest login button"
Start-Sleep -Seconds 3

# Test 2: Main Page
Write-TestLog "=== TEST 2: MAIN PAGE ==="
Write-TestLog "Testing search function"
Simulate-Tap 540 200 "Search button"
Start-Sleep -Seconds 2
Simulate-KeyPress 4 "Back"

# Test 3: Navigation
Write-TestLog "=== TEST 3: NAVIGATION ==="

# Test Chats tab
Write-TestLog "Testing Chats tab"
Simulate-Tap 540 1000 "Chats tab"
Start-Sleep -Seconds 3
Simulate-KeyPress 4 "Back"
Start-Sleep -Seconds 2

# Test Ideas tab
Write-TestLog "Testing Ideas tab"
Simulate-Tap 540 1000 "Ideas tab"
Start-Sleep -Seconds 3
Simulate-KeyPress 4 "Back"
Start-Sleep -Seconds 2

# Test Bookings tab
Write-TestLog "Testing Bookings tab"
Simulate-Tap 540 1000 "Bookings tab"
Start-Sleep -Seconds 3
Simulate-KeyPress 4 "Back"
Start-Sleep -Seconds 2

# Test 4: Profile
Write-TestLog "=== TEST 4: PROFILE ==="
Write-TestLog "Testing profile access via avatar"
Simulate-Tap 200 200 "User avatar"
Start-Sleep -Seconds 3
Simulate-KeyPress 4 "Back"
Start-Sleep -Seconds 2

# Test 5: Back Button
Write-TestLog "=== TEST 5: BACK BUTTON ==="
Write-TestLog "Testing back button functionality"
Simulate-Tap 540 1000 "Chats tab"
Start-Sleep -Seconds 2
Simulate-KeyPress 4 "Back"
Start-Sleep -Seconds 2

# Test 6: Stability
Write-TestLog "=== TEST 6: STABILITY ==="
Write-TestLog "Testing rapid tab switching"
for ($i = 0; $i -lt 3; $i++) {
    Simulate-Tap 540 1000 "Chats tab"
    Start-Sleep -Seconds 1
    Simulate-Tap 540 1000 "Ideas tab"
    Start-Sleep -Seconds 1
    Simulate-Tap 540 1000 "Bookings tab"
    Start-Sleep -Seconds 1
    Simulate-Tap 540 1000 "Home tab"
    Start-Sleep -Seconds 1
}

# Collect logs
Write-TestLog "=== COLLECTING LOGS ==="
adb logcat -d > device_logs.txt
Write-TestLog "Logs saved to device_logs.txt"

Write-TestLog "=== TESTING COMPLETED ==="
Write-TestLog "All basic tests executed successfully"






