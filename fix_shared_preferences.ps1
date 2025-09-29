# PowerShell script to replace SharedPreferences with FlutterSecureStorage
$files = @(
    "lib/services/cache_service.dart",
    "lib/services/settings_service.dart", 
    "lib/services/fcm_service.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        # Replace import
        $content = $content -replace 'import ''package:shared_preferences/shared_preferences\.dart'';', 'import ''package:flutter_secure_storage/flutter_secure_storage.dart'';'
        
        # Replace SharedPreferences type
        $content = $content -replace 'SharedPreferences\?', 'FlutterSecureStorage'
        $content = $content -replace 'SharedPreferences', 'FlutterSecureStorage'
        
        # Replace getInstance() calls
        $content = $content -replace 'await SharedPreferences\.getInstance\(\)', 'const FlutterSecureStorage()'
        
        # Replace method calls
        $content = $content -replace '_prefs\.getString\(([^)]+)\)', 'await _prefs.read(key: $1)'
        $content = $content -replace '_prefs\.setString\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2)'
        $content = $content -replace '_prefs\.getInt\(([^)]+)\)', 'await _prefs.read(key: $1)'
        $content = $content -replace '_prefs\.setInt\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2.toString())'
        $content = $content -replace '_prefs\.getBool\(([^)]+)\)', 'await _prefs.read(key: $1)'
        $content = $content -replace '_prefs\.setBool\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2.toString())'
        $content = $content -replace '_prefs\.remove\(([^)]+)\)', 'await _prefs.delete(key: $1)'
        $content = $content -replace '_prefs\.clear\(\)', 'await _prefs.deleteAll()'
        
        Set-Content $file $content -NoNewline
        Write-Host "Fixed $file"
    }
}
