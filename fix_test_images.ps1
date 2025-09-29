# PowerShell script to fix test images
$testFiles = Get-ChildItem -Path "test" -Recurse -Filter "*.dart"

foreach ($file in $testFiles) {
  $content = Get-Content $file.FullName -Raw
    
  # Replace network images with local assets
  $content = $content -replace 'NetworkImage\("https://via\.placeholder\.com/[^"]*"\)', 'AssetImage("assets/images/placeholder.png")'
  $content = $content -replace 'NetworkImage\("https://[^"]*"\)', 'AssetImage("assets/images/placeholder.png")'
    
  # Add image loading mock
  if ($content -match "testWidgets") {
    $content = $content -replace "(testWidgets\('[^']*', \([^)]*\) async \{)", "`$1`n    // Mock network images`n    HttpOverrides.global = TestHttpOverrides();"
  }
    
  Set-Content $file.FullName $content -NoNewline
  Write-Host "Fixed images in $($file.Name)"
}
