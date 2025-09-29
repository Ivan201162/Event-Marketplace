# PowerShell script to fix Android plugin registration issues
$filePath = "android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"

if (Test-Path $filePath) {
  $content = Get-Content $filePath -Raw
    
  # Remove problematic plugins
  $content = $content -replace '    try \{\s*flutterEngine\.getPlugins\(\)\.add\(new com\.baseflow\.geolocator\.GeolocatorPlugin\(\)\);\s*\} catch \(Exception e\) \{\s*Log\.e\(TAG, "Error registering plugin geolocator_android, com\.baseflow\.geolocator\.GeolocatorPlugin", e\);\s*\}', '    // GeolocatorPlugin removed for release builds'
    
  $content = $content -replace '    try \{\s*flutterEngine\.getPlugins\(\)\.add\(new dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin\(\)\);\s*\} catch \(Exception e\) \{\s*Log\.e\(TAG, "Error registering plugin integration_test, dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin", e\);\s*\}', '    // IntegrationTestPlugin removed for release builds'
    
  $content = $content -replace '    try \{\s*flutterEngine\.getPlugins\(\)\.add\(new io\.flutter\.plugins\.sharedpreferences\.SharedPreferencesPlugin\(\)\);\s*\} catch \(Exception e\) \{\s*Log\.e\(TAG, "Error registering plugin shared_preferences_android, io\.flutter\.plugins\.sharedpreferences\.SharedPreferencesPlugin", e\);\s*\}', '    // SharedPreferencesPlugin removed for release builds'
    
  Set-Content $filePath $content -NoNewline
  Write-Host "Android plugin registration file fixed successfully!"
}
else {
  Write-Host "File not found: $filePath"
}
