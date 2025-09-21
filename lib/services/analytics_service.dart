import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../core/platform/platform_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/analytics_event.dart';

/// Сервис аналитики использования приложения
class AnalyticsService {
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  static final AnalyticsService _instance = AnalyticsService._internal();

  String? _currentSessionId;
  String? _currentUserId;
  String? _deviceId;
  String? _appVersion;
  String? _platform;
  Timer? _sessionTimer;
  final List<String> _currentScreens = [];
  int _eventCount = 0;

  /// Инициализация сервиса аналитики
  Future<void> initialize() async {
    try {
      _deviceId = await _getDeviceId();
      _appVersion = await _getAppVersion();
      _platform = _getPlatform();
      await _startNewSession();
      _sessionTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _updateSession();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации аналитики: $e');
      }
    }
  }

  /// Установить текущего пользователя
  Future<void> setUserId(String? userId) async {
    _currentUserId = userId;
    if (_currentSessionId != null) {
      await _updateSession();
    }
  }

  /// Логировать событие
  Future<void> logEvent({
    required String eventName,
    required String screen,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      if (_currentSessionId == null) {
        await _startNewSession();
      }

      final event = AnalyticsEvent(
        id: _uuid.v4(),
        userId: _currentUserId,
        eventName: eventName,
        screen: screen,
        parameters: parameters ?? {},
        timestamp: DateTime.now(),
        sessionId: _currentSessionId!,
        deviceId: _deviceId!,
        appVersion: _appVersion!,
        platform: _platform!,
      );

      await _firestore.collection('analyticsEvents').add(event.toMap());
      _eventCount++;

      if (!_currentScreens.contains(screen)) {
        _currentScreens.add(screen);
      }

      await _updateSession();

      if (kDebugMode) {
        print('Analytics Event: $eventName on $screen');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка логирования события: $e');
      }
    }
  }

  /// Логировать просмотр экрана
  Future<void> logScreenView(String screenName) async {
    await logEvent(
      eventName: 'screen_view',
      screen: screenName,
      parameters: {
        'screen_name': screenName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Получить статистику аналитики
  Future<AnalyticsStatistics> getAnalyticsStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 30));
      final end = endDate ?? now;

      final eventsSnapshot = await _firestore
          .collection('analyticsEvents')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final sessionsSnapshot = await _firestore
          .collection('userSessions')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final events =
          eventsSnapshot.docs.map(AnalyticsEvent.fromDocument).toList();

      final sessions =
          sessionsSnapshot.docs.map(UserSession.fromDocument).toList();

      final totalEvents = events.length;
      final uniqueUsers =
          events.map((e) => e.userId).where((id) => id != null).toSet().length;
      final activeSessions = sessions.length;

      final eventsByCategory = <String, int>{};
      final eventsByScreen = <String, int>{};
      final eventsByPlatform = <String, int>{};
      final eventsByVersion = <String, int>{};

      for (final event in events) {
        eventsByCategory[event.category.name] =
            (eventsByCategory[event.category.name] ?? 0) + 1;
        eventsByScreen[event.screen] = (eventsByScreen[event.screen] ?? 0) + 1;
        eventsByPlatform[event.platform] =
            (eventsByPlatform[event.platform] ?? 0) + 1;
        eventsByVersion[event.appVersion] =
            (eventsByVersion[event.appVersion] ?? 0) + 1;
      }

      return AnalyticsStatistics(
        totalEvents: totalEvents,
        uniqueUsers: uniqueUsers,
        activeSessions: activeSessions,
        eventsByCategory: eventsByCategory,
        eventsByScreen: eventsByScreen,
        eventsByPlatform: eventsByPlatform,
        eventsByVersion: eventsByVersion,
        periodStart: start,
        periodEnd: end,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения статистики аналитики: $e');
      }
      return AnalyticsStatistics(
        totalEvents: 0,
        uniqueUsers: 0,
        activeSessions: 0,
        eventsByCategory: {},
        eventsByScreen: {},
        eventsByPlatform: {},
        eventsByVersion: {},
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
      );
    }
  }

  /// Создать новую сессию
  Future<void> _startNewSession() async {
    try {
      _currentSessionId = _uuid.v4();
      _currentScreens.clear();
      _eventCount = 0;

      final session = UserSession(
        sessionId: _currentSessionId!,
        userId: _currentUserId,
        deviceId: _deviceId!,
        startTime: DateTime.now(),
        platform: _platform!,
        appVersion: _appVersion!,
        screens: [],
        eventCount: 0,
      );

      await _firestore
          .collection('userSessions')
          .doc(_currentSessionId)
          .set(session.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания новой сессии: $e');
      }
    }
  }

  /// Обновить текущую сессию
  Future<void> _updateSession() async {
    try {
      if (_currentSessionId == null) return;

      await _firestore
          .collection('userSessions')
          .doc(_currentSessionId)
          .update({
        'userId': _currentUserId,
        'screens': _currentScreens,
        'eventCount': _eventCount,
        'lastActivity': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обновления сессии: $e');
      }
    }
  }

  /// Получить ID устройства
  Future<String> _getDeviceId() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      } else {
        return 'unknown';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  /// Получить версию приложения
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Получить платформу
  String _getPlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.linux:
        return 'web';
      default:
        return 'unknown';
    }
  }

  /// Получить топ события
  Future<List<Map<String, dynamic>>> getTopEvents({
    int limit = 10,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _firestore
          .collection('events')
          .orderBy('participantsCount', descending: true)
          .limit(limit);

      if (fromDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }

      if (toDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения топ событий: $e');
      }
      return [];
    }
  }

  /// Закрыть сервис
  void dispose() {
    _sessionTimer?.cancel();
  }
}
