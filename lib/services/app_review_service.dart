import 'dart:io';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Сервис для работы с отзывами о приложении
class AppReviewService {
  static const String _lastReviewRequestKey = 'last_review_request';
  static const String _reviewCountKey = 'review_count';
  static const String _isReviewDismissedKey = 'is_review_dismissed';
  static const String _appLaunchCountKey = 'app_launch_count';
  static const String _lastFeatureUsedKey = 'last_feature_used';

  static const int _minLaunchesBeforeReview = 5;
  static const int _minDaysBetweenReviews = 30;
  static const int _maxReviewRequests = 3;

  /// Проверить, доступен ли in-app review
  static Future<bool> isAvailable() async {
    try {
      final inAppReview = InAppReview.instance;
      return await inAppReview.isAvailable();
    } catch (e) {
      debugPrint('Ошибка проверки доступности in-app review: $e');
      return false;
    }
  }

  /// Запросить отзыв
  static Future<void> requestReview() async {
    try {
      final inAppReview = InAppReview.instance;

      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await _updateLastReviewRequest();
        await _incrementReviewCount();
      } else {
        // Fallback: открыть страницу в магазине
        await openStoreListing();
      }
    } catch (e) {
      debugPrint('Ошибка запроса отзыва: $e');
    }
  }

  /// Открыть страницу приложения в магазине
  static Future<void> openStoreListing() async {
    try {
      final inAppReview = InAppReview.instance;
      await inAppReview.openStoreListing();
      await _updateLastReviewRequest();
      await _incrementReviewCount();
    } catch (e) {
      debugPrint('Ошибка открытия страницы в магазине: $e');
    }
  }

  /// Проверить, нужно ли показать запрос на отзыв
  static Future<bool> shouldShowReviewRequest() async {
    try {
      // Проверяем, не был ли отзыв отклонен
      final isDismissed = await _isReviewDismissed();
      if (isDismissed) return false;

      // Проверяем количество запросов
      final reviewCount = await _getReviewCount();
      if (reviewCount >= _maxReviewRequests) return false;

      // Проверяем время последнего запроса
      final lastRequest = await _getLastReviewRequest();
      if (lastRequest != null) {
        final daysSinceLastRequest = DateTime.now().difference(lastRequest).inDays;
        if (daysSinceLastRequest < _minDaysBetweenReviews) return false;
      }

      // Проверяем количество запусков
      final launchCount = await _getAppLaunchCount();
      if (launchCount < _minLaunchesBeforeReview) return false;

      return true;
    } catch (e) {
      debugPrint('Ошибка проверки необходимости показа отзыва: $e');
      return false;
    }
  }

  /// Увеличить счетчик запусков приложения
  static Future<void> incrementAppLaunchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_appLaunchCountKey) ?? 0;
      await prefs.setInt(_appLaunchCountKey, currentCount + 1);
    } catch (e) {
      debugPrint('Ошибка увеличения счетчика запусков: $e');
    }
  }

  /// Отметить использование функции
  static Future<void> markFeatureUsed(String featureName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastFeatureUsedKey, featureName);
      await prefs.setInt('${_lastFeatureUsedKey}_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Ошибка отметки использования функции: $e');
    }
  }

  /// Отклонить запрос на отзыв
  static Future<void> dismissReviewRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isReviewDismissedKey, true);
    } catch (e) {
      debugPrint('Ошибка отклонения запроса на отзыв: $e');
    }
  }

  /// Сбросить состояние отзыва
  static Future<void> resetReviewState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isReviewDismissedKey);
      await prefs.remove(_lastReviewRequestKey);
      await prefs.remove(_reviewCountKey);
    } catch (e) {
      debugPrint('Ошибка сброса состояния отзыва: $e');
    }
  }

  /// Получить статистику отзывов
  static Future<ReviewStats> getReviewStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final launchCount = prefs.getInt(_appLaunchCountKey) ?? 0;
      final reviewCount = prefs.getInt(_reviewCountKey) ?? 0;
      final lastRequest = prefs.getInt(_lastReviewRequestKey);
      final isDismissed = prefs.getBool(_isReviewDismissedKey) ?? false;
      final lastFeatureUsed = prefs.getString(_lastFeatureUsedKey);
      final lastFeatureTime = prefs.getInt('${_lastFeatureUsedKey}_time');

      return ReviewStats(
        appLaunchCount: launchCount,
        reviewRequestCount: reviewCount,
        lastReviewRequest: lastRequest != null
            ? DateTime.fromMillisecondsSinceEpoch(lastRequest)
            : null,
        isDismissed: isDismissed,
        lastFeatureUsed: lastFeatureUsed,
        lastFeatureUsedTime: lastFeatureTime != null
            ? DateTime.fromMillisecondsSinceEpoch(lastFeatureTime)
            : null,
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики отзывов: $e');
      return const ReviewStats(appLaunchCount: 0, reviewRequestCount: 0, isDismissed: false);
    }
  }

  /// Получить время последнего запроса на отзыв
  static Future<DateTime?> _getLastReviewRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastReviewRequestKey);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      debugPrint('Ошибка получения времени последнего запроса: $e');
      return null;
    }
  }

  /// Обновить время последнего запроса на отзыв
  static Future<void> _updateLastReviewRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastReviewRequestKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Ошибка обновления времени запроса: $e');
    }
  }

  /// Получить количество запросов на отзыв
  static Future<int> _getReviewCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_reviewCountKey) ?? 0;
    } catch (e) {
      debugPrint('Ошибка получения количества запросов: $e');
      return 0;
    }
  }

  /// Увеличить счетчик запросов на отзыв
  static Future<void> _incrementReviewCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_reviewCountKey) ?? 0;
      await prefs.setInt(_reviewCountKey, currentCount + 1);
    } catch (e) {
      debugPrint('Ошибка увеличения счетчика запросов: $e');
    }
  }

  /// Проверить, был ли отзыв отклонен
  static Future<bool> _isReviewDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isReviewDismissedKey) ?? false;
    } catch (e) {
      debugPrint('Ошибка проверки отклонения отзыва: $e');
      return false;
    }
  }

  /// Получить количество запусков приложения
  static Future<int> _getAppLaunchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_appLaunchCountKey) ?? 0;
    } catch (e) {
      debugPrint('Ошибка получения количества запусков: $e');
      return 0;
    }
  }

  /// Открыть страницу отзывов в браузере
  static Future<void> openReviewPageInBrowser() async {
    try {
      String url;
      if (Platform.isAndroid) {
        url = 'https://play.google.com/store/apps/details?id=com.example.event_marketplace_app';
      } else if (Platform.isIOS) {
        url = 'https://apps.apple.com/app/id1234567890';
      } else {
        url = 'https://example.com/review';
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Ошибка открытия страницы отзывов в браузере: $e');
    }
  }

  /// Получить рекомендуемое время для запроса отзыва
  static Future<ReviewTiming> getRecommendedTiming() async {
    try {
      final stats = await getReviewStats();
      final launchCount = stats.appLaunchCount;
      final reviewCount = stats.reviewRequestCount;
      final lastRequest = stats.lastReviewRequest;
      final lastFeatureTime = stats.lastFeatureUsedTime;

      // Определяем лучшее время для запроса
      if (launchCount >= _minLaunchesBeforeReview &&
          reviewCount < _maxReviewRequests &&
          (lastRequest == null ||
              DateTime.now().difference(lastRequest).inDays >= _minDaysBetweenReviews)) {
        // Проверяем, использовалась ли недавно функция
        if (lastFeatureTime != null && DateTime.now().difference(lastFeatureTime).inMinutes < 5) {
          return ReviewTiming.now;
        }

        return ReviewTiming.soon;
      }

      return ReviewTiming.notYet;
    } catch (e) {
      debugPrint('Ошибка получения рекомендуемого времени: $e');
      return ReviewTiming.notYet;
    }
  }
}

/// Статистика отзывов
class ReviewStats {
  const ReviewStats({
    required this.appLaunchCount,
    required this.reviewRequestCount,
    this.lastReviewRequest,
    required this.isDismissed,
    this.lastFeatureUsed,
    this.lastFeatureUsedTime,
  });
  final int appLaunchCount;
  final int reviewRequestCount;
  final DateTime? lastReviewRequest;
  final bool isDismissed;
  final String? lastFeatureUsed;
  final DateTime? lastFeatureUsedTime;

  /// Получить время последнего запроса в читаемом виде
  String get formattedLastRequest {
    if (lastReviewRequest == null) return 'Никогда';

    final now = DateTime.now();
    final difference = now.difference(lastReviewRequest!);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else {
      return '${difference.inDays} дн. назад';
    }
  }

  /// Получить время последнего использования функции в читаемом виде
  String get formattedLastFeatureTime {
    if (lastFeatureUsedTime == null) return 'Никогда';

    final now = DateTime.now();
    final difference = now.difference(lastFeatureUsedTime!);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else {
      return '${difference.inDays} дн. назад';
    }
  }

  /// Проверить, можно ли запросить отзыв
  bool get canRequestReview =>
      appLaunchCount >= AppReviewService._minLaunchesBeforeReview &&
      reviewRequestCount < AppReviewService._maxReviewRequests &&
      !isDismissed &&
      (lastReviewRequest == null ||
          DateTime.now().difference(lastReviewRequest!).inDays >=
              AppReviewService._minDaysBetweenReviews);
}

/// Время для запроса отзыва
enum ReviewTiming { now, soon, notYet }

/// Типы функций для отслеживания
enum FeatureType { booking, search, chat, profile, payment, review, share, favorite }
