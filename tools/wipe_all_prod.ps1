# Production Data Wipe Script
$PROJECT_ID = "event-marketplace-mvp"
$COLLECTIONS = @(
    "users", "user_profiles", "specialists", "follows", "posts", "post_likes", "post_comments",
    "ideas", "idea_likes", "idea_comments", "stories", "requests", "chats", "messages",
    "notifications", "categories", "tariffs", "plans", "feed"
)

$STORAGE_PREFIXES = @(
    "uploads/avatars",
    "uploads/posts",
    "uploads/reels",
    "uploads/ideas",
    "uploads/stories"
)

$results = @()
$totalDocs = 0
$totalFiles = 0

Write-Host "🗑️  Starting production data wipe...`n"

# Wipe Firestore collections
foreach ($collection in $COLLECTIONS) {
    try {
        Write-Host "Deleting collection: $collection..."
        $output = firebase firestore:delete --project $PROJECT_ID --recursive --force $collection 2>&1 | Out-String
        
        $deleted = if ($output -match '(\d+)\s+(?:documents?|items?)') { [int]$matches[1] } else { 0 }
        $totalDocs += $deleted
        
        $results += @{ Collection = $collection; Deleted = $deleted; Success = $true }
        Write-Host "  ✅ $collection`: $deleted documents deleted"
    } catch {
        $errorMsg = $_.Exception.Message
        if ($errorMsg -match "not found|does not exist") {
            $results += @{ Collection = $collection; Deleted = 0; Success = $true; Error = "Collection not found" }
            Write-Host "  ⚠️  $collection`: not found (skipped)"
        } else {
            $results += @{ Collection = $collection; Deleted = 0; Success = $false; Error = $errorMsg }
            Write-Host "  ❌ $collection`: $errorMsg"
        }
    }
}

# Wipe Storage prefixes
Write-Host "`n🗑️  Deleting Storage files...`n"
foreach ($prefix in $STORAGE_PREFIXES) {
    try {
        Write-Host "Deleting storage prefix: $prefix..."
        $output = gsutil -m rm -r "gs://${PROJECT_ID}.appspot.com/${prefix}/**" 2>&1 | Out-String
        
        $deleted = if ($output -match "Removing gs://[^\s]+/(\d+)") { [int]$matches[1] } else { 0 }
        $totalFiles += $deleted
        
        Write-Host "  ✅ $prefix`: $deleted files deleted"
    } catch {
        $errorMsg = $_.Exception.Message
        if ($errorMsg -match "does not exist|No such file") {
            Write-Host "  ⚠️  $prefix`: not found (skipped)"
        } else {
            Write-Host "  ❌ $prefix`: $errorMsg"
        }
    }
}

Write-Host "`n✅ Cleanup complete!`n"
Write-Host "SUMMARY:"
Write-Host "  Total Firestore documents deleted: $totalDocs"
Write-Host "  Total Storage files deleted: $totalFiles"
Write-Host "  Collections processed: $($results.Count)"

# Output JSON for parsing
Write-Host "`n---DELETION_RESULTS---"
$json = @{
    totalDocs = $totalDocs
    totalFiles = $totalFiles
    collections = $results
} | ConvertTo-Json -Depth 10
Write-Host $json

