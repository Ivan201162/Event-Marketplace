# Скрипт для исправления debugPrint в Dart файлах
$files = @(
  "lib/providers/image_cache_provider.dart",
  "lib/providers/theme_provider.dart",
  "lib/screens/enhanced_chat_screen.dart",
  "lib/screens/enhanced_order_screen.dart",
  "lib/screens/home_screen.dart",
  "lib/screens/main_navigation_screen.dart",
  "lib/screens/my_bookings_screen.dart",
  "lib/screens/organizer_proposals_screen.dart",
  "lib/screens/specialist_reviews_screen.dart",
  "lib/screens/splash_screen.dart",
  "lib/screens/video_reels_viewer.dart",
  "lib/screens/subscription/subscription_screen.dart",
  "lib/services/ab_testing_service.dart",
  "lib/services/admin_service.dart",
  "lib/services/ai_assistant_service.dart",
  "lib/services/ai_chat_service.dart",
  "lib/services/analytics_service.dart",
  "lib/services/automated_promotions_service.dart",
  "lib/services/calendar_service.dart",
  "lib/services/chat_service.dart",
  "lib/services/dynamic_pricing_service.dart",
  "lib/services/enhanced_chats_service.dart",
  "lib/services/enhanced_notifications_service.dart",
  "lib/services/enhanced_orders_service.dart",
  "lib/services/fcm_service.dart",
  "lib/services/growth_mechanics_service.dart",
  "lib/services/growth_notifications_service.dart",
  "lib/services/growth_pack_integration_service.dart",
  "lib/services/ideas_service.dart",
  "lib/services/marketing_admin_service.dart",
  "lib/services/mock_auth_service.dart",
  "lib/services/notification_service.dart",
  "lib/services/organizer_service.dart",
  "lib/services/partnership_service.dart",
  "lib/services/payment_extended_service.dart",
  "lib/services/profile_service.dart",
  "lib/services/receipt_service.dart",
  "lib/services/referral_service.dart",
  "lib/services/revenue_analytics_service.dart",
  "lib/services/reviews_service.dart",
  "lib/services/session_service.dart",
  "lib/services/smart_advertising_service.dart",
  "lib/services/smart_search_service.dart",
  "lib/services/smart_specialist_data_generator.dart",
  "lib/services/specialist_profile_service.dart",
  "lib/services/specialist_report_service.dart",
  "lib/services/specialist_service.dart",
  "lib/services/test_data_generator.dart",
  "lib/services/test_data_service.dart",
  "lib/services/test_notifications_service.dart"
)

foreach ($file in $files) {
  if (Test-Path $file) {
    $content = Get-Content $file -Raw
    if ($content -match "debugPrint" -and $content -notmatch "import.*foundation") {
      # Добавляем импорт foundation после первого import
      $content = $content -replace "(import '[^']+';)", "`$1`nimport 'package:flutter/foundation.dart';"
      Set-Content $file $content -Encoding UTF8
      Write-Host "Fixed: $file"
    }
  }
}

