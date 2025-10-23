import 'package:flutter/foundation.dart';

/// Заглушка для url_launcher
class UrlLauncher {
  static Future<bool> canLaunchUrl(Uri url) async {
    if (kDebugMode) {
      debugPrint('UrlLauncher.canLaunchUrl not implemented - using mock');
    }
    return true;
  }

  static Future<bool> launchUrl(Uri url,
      {LaunchMode mode = LaunchMode.platformDefault}) async {
    if (kDebugMode) {
      debugPrint('UrlLauncher.launchUrl not implemented - using mock');
      debugPrint('Would launch URL: $url with mode: $mode');
    }
    return true;
  }
}

/// Режим запуска URL
enum LaunchMode {
  platformDefault,
  inAppWebView,
  externalApplication,
  externalNonBrowserApplication,
}
