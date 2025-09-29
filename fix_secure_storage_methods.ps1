# PowerShell script to fix FlutterSecureStorage method calls
$files = @(
    "lib/services/cache_service.dart",
    "lib/services/settings_service.dart", 
    "lib/services/fcm_service.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        # Remove getInstance() calls
        $content = $content -replace 'await FlutterSecureStorage\.getInstance\(\)', 'const FlutterSecureStorage()'
        
        # Fix method calls - getInt
        $content = $content -replace '_prefs\?\.getInt\(([^)]+)\)', 'int.tryParse(await _prefs.read(key: $1) ?? "0") ?? 0'
        $content = $content -replace '_prefs!\.getInt\(([^)]+)\)', 'int.tryParse(await _prefs.read(key: $1) ?? "0") ?? 0'
        
        # Fix method calls - setInt
        $content = $content -replace '_prefs\?\.setInt\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2.toString())'
        $content = $content -replace '_prefs!\.setInt\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2.toString())'
        
        # Fix method calls - getString
        $content = $content -replace '_prefs\?\.getString\(([^)]+)\)', 'await _prefs.read(key: $1)'
        $content = $content -replace '_prefs!\.getString\(([^)]+)\)', 'await _prefs.read(key: $1)'
        
        # Fix method calls - setString
        $content = $content -replace '_prefs\?\.setString\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2)'
        $content = $content -replace '_prefs!\.setString\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2)'
        
        # Fix method calls - getBool
        $content = $content -replace '_prefs\?\.getBool\(([^)]+)\)', 'bool.tryParse(await _prefs.read(key: $1) ?? "false") ?? false'
        $content = $content -replace '_prefs!\.getBool\(([^)]+)\)', 'bool.tryParse(await _prefs.read(key: $1) ?? "false") ?? false'
        
        # Fix method calls - setBool
        $content = $content -replace '_prefs\?\.setBool\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2.toString())'
        $content = $content -replace '_prefs!\.setBool\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2.toString())'
        
        # Fix method calls - getDouble
        $content = $content -replace '_prefs\?\.getDouble\(([^)]+)\)', 'double.tryParse(await _prefs.read(key: $1) ?? "0.0") ?? 0.0'
        $content = $content -replace '_prefs!\.getDouble\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2.toString())'
        
        # Fix method calls - setDouble
        $content = $content -replace '_prefs\?\.setDouble\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2.toString())'
        $content = $content -replace '_prefs!\.setDouble\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: $2.toString())'
        
        # Fix method calls - setStringList
        $content = $content -replace '_prefs\?\.setStringList\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: json.encode($2))'
        $content = $content -replace '_prefs!\.setStringList\(([^,]+),\s*([^)]+)\)', 'await _prefs.write(key: $1, value: json.encode($2))'
        
        # Fix method calls - remove
        $content = $content -replace '_prefs\?\.remove\(([^)]+)\)', 'await _prefs.delete(key: $1)'
        $content = $content -replace '_prefs!\.remove\(([^)]+)\)', 'await _prefs.delete(key: $1)'
        
        # Fix method calls - getKeys
        $content = $content -replace '_prefs\?\.getKeys\(\)', 'await _prefs.readAll().then((map) => map.keys)'
        $content = $content -replace '_prefs!\.getKeys\(\)', 'await _prefs.readAll().then((map) => map.keys)'
        
        # Fix method calls - get
        $content = $content -replace '_prefs\?\.get\(([^)]+)\)', 'await _prefs.read(key: $1)'
        $content = $content -replace '_prefs!\.get\(([^)]+)\)', 'await _prefs.read(key: $1)'
        
        Set-Content $file $content -NoNewline
        Write-Host "Fixed methods in $file"
    }
}
