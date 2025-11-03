import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Сервис для логирования событий аналитики
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Защита от спама: debounce для одинаковых действий
  final Map<String, DateTime> _lastEventTimes = {};
  static const Duration debounceWindow = Duration(seconds: 2);

  /// Проверить, можно ли логировать событие (debounce)
  bool _canLogEvent(String eventKey) {
    final now = DateTime.now();
    final lastTime = _lastEventTimes[eventKey];

    if (lastTime != null && now.difference(lastTime) < debounceWindow) {
      return false; // Слишком рано после предыдущего события
    }

    _lastEventTimes[eventKey] = now;
    return true;
  }

  /// Логировать просмотр профиля специалиста
  Future<void> logProfileView(String specId) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ AnalyticsService: Cannot log profile view - user not authenticated');
      return;
    }

    final eventKey = 'profile_view_${specId}_${user.uid}';
    if (!_canLogEvent(eventKey)) {
      debugPrint('⚠️ AnalyticsService: Profile view debounced');
      return;
    }

    try {
      await _firestore.collection('events_profile_views').add({
        'specId': specId,
        'viewerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ AnalyticsService: Profile view logged for $specId');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error logging profile view: $e');
    }
  }

  /// Логировать взаимодействие с постом (лайк/коммент/шаринг)
  Future<void> logPostEngagement({
    required String specId,
    required String postId,
    required String type, // 'like' | 'comment' | 'share'
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ AnalyticsService: Cannot log post engagement - user not authenticated');
      return;
    }

    if (!['like', 'comment', 'share'].contains(type)) {
      debugPrint('❌ AnalyticsService: Invalid engagement type: $type');
      return;
    }

    final eventKey = 'post_${type}_${postId}_${user.uid}';
    if (!_canLogEvent(eventKey)) {
      debugPrint('⚠️ AnalyticsService: Post engagement debounced');
      return;
    }

    try {
      await _firestore.collection('events_post_engagement').add({
        'specId': specId,
        'actorId': user.uid,
        'postId': postId,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ AnalyticsService: Post engagement logged: $type for post $postId');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error logging post engagement: $e');
    }
  }

  /// Логировать подписку на специалиста
  Future<void> logFollow({
    required String specId,
    required String source, // 'profile' | 'post' | 'search'
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ AnalyticsService: Cannot log follow - user not authenticated');
      return;
    }

    final eventKey = 'follow_${specId}_${user.uid}';
    if (!_canLogEvent(eventKey)) {
      debugPrint('⚠️ AnalyticsService: Follow debounced');
      return;
    }

    try {
      await _firestore.collection('events_follow').add({
        'specId': specId,
        'followerId': user.uid,
        'source': source,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ AnalyticsService: Follow logged for $specId from $source');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error logging follow: $e');
    }
  }

  /// Логировать событие заявки
  Future<void> logRequestEvent({
    required String specId,
    required String requestId,
    required String status, // 'created' | 'completed'
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ AnalyticsService: Cannot log request event - user not authenticated');
      return;
    }

    if (!['created', 'completed'].contains(status)) {
      debugPrint('❌ AnalyticsService: Invalid request status: $status');
      return;
    }

    final eventKey = 'request_${status}_${requestId}_${user.uid}';
    if (!_canLogEvent(eventKey)) {
      debugPrint('⚠️ AnalyticsService: Request event debounced');
      return;
    }

    try {
      await _firestore.collection('events_requests').add({
        'specId': specId,
        'customerId': user.uid,
        'requestId': requestId,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ AnalyticsService: Request event logged: $status for request $requestId');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error logging request event: $e');
    }
  }
}

}