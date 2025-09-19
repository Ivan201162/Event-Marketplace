import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель события аналитики
class AnalyticsEvent {
  const AnalyticsEvent({
    required this.id,
    this.userId,
    required this.eventName,
    required this.screen,
    required this.parameters,
    required this.timestamp,
    required this.sessionId,
    required this.deviceId,
    required this.appVersion,
    required this.platform,
  });

  /// Создать из документа Firestore
  factory AnalyticsEvent.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalyticsEvent(
      id: doc.id,
      userId: data['userId'],
      eventName: data['eventName'] ?? '',
      screen: data['screen'] ?? '',
      parameters: Map<String, dynamic>.from(data['parameters'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      sessionId: data['sessionId'] ?? '',
      deviceId: data['deviceId'] ?? '',
      appVersion: data['appVersion'] ?? '',
      platform: data['platform'] ?? '',
    );
  }

  /// Создать из Map
  factory AnalyticsEvent.fromMap(Map<String, dynamic> data) => AnalyticsEvent(
        id: data['id'] ?? '',
        userId: data['userId'],
        eventName: data['eventName'] ?? '',
        screen: data['screen'] ?? '',
        parameters: Map<String, dynamic>.from(data['parameters'] ?? {}),
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        sessionId: data['sessionId'] ?? '',
        deviceId: data['deviceId'] ?? '',
        appVersion: data['appVersion'] ?? '',
        platform: data['platform'] ?? '',
      );
  final String id;
  final String? userId;
  final String eventName;
  final String screen;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String sessionId;
  final String deviceId;
  final String appVersion;
  final String platform;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'eventName': eventName,
        'screen': screen,
        'parameters': parameters,
        'timestamp': Timestamp.fromDate(timestamp),
        'sessionId': sessionId,
        'deviceId': deviceId,
        'appVersion': appVersion,
        'platform': platform,
      };

  /// Создать копию с изменениями
  AnalyticsEvent copyWith({
    String? id,
    String? userId,
    String? eventName,
    String? screen,
    Map<String, dynamic>? parameters,
    DateTime? timestamp,
    String? sessionId,
    String? deviceId,
    String? appVersion,
    String? platform,
  }) =>
      AnalyticsEvent(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        eventName: eventName ?? this.eventName,
        screen: screen ?? this.screen,
        parameters: parameters ?? this.parameters,
        timestamp: timestamp ?? this.timestamp,
        sessionId: sessionId ?? this.sessionId,
        deviceId: deviceId ?? this.deviceId,
        appVersion: appVersion ?? this.appVersion,
        platform: platform ?? this.platform,
      );

  /// Получить категорию события
  EventCategory get category {
    switch (eventName) {
      case 'screen_view':
        return EventCategory.navigation;
      case 'user_register':
      case 'user_login':
      case 'user_logout':
        return EventCategory.authentication;
      case 'booking_created':
      case 'booking_confirmed':
      case 'booking_cancelled':
        return EventCategory.booking;
      case 'payment_initiated':
      case 'payment_completed':
      case 'payment_failed':
        return EventCategory.payment;
      case 'search_performed':
      case 'filter_applied':
        return EventCategory.search;
      case 'review_submitted':
      case 'rating_given':
        return EventCategory.review;
      case 'chat_message_sent':
      case 'chat_opened':
        return EventCategory.communication;
      case 'profile_updated':
      case 'settings_changed':
        return EventCategory.profile;
      default:
        return EventCategory.other;
    }
  }

  /// Получить важность события
  EventImportance get importance {
    switch (eventName) {
      case 'user_register':
      case 'booking_created':
      case 'payment_completed':
        return EventImportance.high;
      case 'user_login':
      case 'booking_confirmed':
      case 'review_submitted':
        return EventImportance.medium;
      case 'screen_view':
      case 'search_performed':
        return EventImportance.low;
      default:
        return EventImportance.medium;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsEvent &&
        other.id == id &&
        other.userId == userId &&
        other.eventName == eventName &&
        other.screen == screen &&
        other.parameters == parameters &&
        other.timestamp == timestamp &&
        other.sessionId == sessionId &&
        other.deviceId == deviceId &&
        other.appVersion == appVersion &&
        other.platform == platform;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        eventName,
        screen,
        parameters,
        timestamp,
        sessionId,
        deviceId,
        appVersion,
        platform,
      );

  @override
  String toString() =>
      'AnalyticsEvent(id: $id, eventName: $eventName, screen: $screen)';
}

/// Категории событий
enum EventCategory {
  navigation,
  authentication,
  booking,
  payment,
  search,
  review,
  communication,
  profile,
  other,
}

/// Важность событий
enum EventImportance {
  low,
  medium,
  high,
}

/// Статистика аналитики
class AnalyticsStatistics {
  const AnalyticsStatistics({
    required this.totalEvents,
    required this.uniqueUsers,
    required this.activeSessions,
    required this.eventsByCategory,
    required this.eventsByScreen,
    required this.eventsByPlatform,
    required this.eventsByVersion,
    required this.periodStart,
    required this.periodEnd,
  });
  final int totalEvents;
  final int uniqueUsers;
  final int activeSessions;
  final Map<String, int> eventsByCategory;
  final Map<String, int> eventsByScreen;
  final Map<String, int> eventsByPlatform;
  final Map<String, int> eventsByVersion;
  final DateTime periodStart;
  final DateTime periodEnd;

  /// Получить самый популярный экран
  String? get mostPopularScreen {
    if (eventsByScreen.isEmpty) return null;
    return eventsByScreen.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Получить самую популярную категорию
  String? get mostPopularCategory {
    if (eventsByCategory.isEmpty) return null;
    return eventsByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Получить самую популярную платформу
  String? get mostPopularPlatform {
    if (eventsByPlatform.isEmpty) return null;
    return eventsByPlatform.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Получить среднее количество событий на пользователя
  double get averageEventsPerUser {
    if (uniqueUsers == 0) return 0;
    return totalEvents / uniqueUsers;
  }

  /// Получить среднее количество событий на сессию
  double get averageEventsPerSession {
    if (activeSessions == 0) return 0;
    return totalEvents / activeSessions;
  }

  @override
  String toString() =>
      'AnalyticsStatistics(totalEvents: $totalEvents, uniqueUsers: $uniqueUsers, activeSessions: $activeSessions)';
}

/// Сессия пользователя
class UserSession {
  const UserSession({
    required this.sessionId,
    this.userId,
    required this.deviceId,
    required this.startTime,
    this.endTime,
    required this.platform,
    required this.appVersion,
    required this.screens,
    required this.eventCount,
    this.duration,
  });

  /// Создать из документа Firestore
  factory UserSession.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSession(
      sessionId: doc.id,
      userId: data['userId'],
      deviceId: data['deviceId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      platform: data['platform'] ?? '',
      appVersion: data['appVersion'] ?? '',
      screens: List<String>.from(data['screens'] ?? []),
      eventCount: data['eventCount'] ?? 0,
      duration:
          data['duration'] != null ? Duration(seconds: data['duration']) : null,
    );
  }

  /// Создать из Map
  factory UserSession.fromMap(Map<String, dynamic> data) => UserSession(
        sessionId: data['sessionId'] ?? '',
        userId: data['userId'],
        deviceId: data['deviceId'] ?? '',
        startTime: (data['startTime'] as Timestamp).toDate(),
        endTime: data['endTime'] != null
            ? (data['endTime'] as Timestamp).toDate()
            : null,
        platform: data['platform'] ?? '',
        appVersion: data['appVersion'] ?? '',
        screens: List<String>.from(data['screens'] ?? []),
        eventCount: data['eventCount'] ?? 0,
        duration: data['duration'] != null
            ? Duration(seconds: data['duration'])
            : null,
      );
  final String sessionId;
  final String? userId;
  final String deviceId;
  final DateTime startTime;
  final DateTime? endTime;
  final String platform;
  final String appVersion;
  final List<String> screens;
  final int eventCount;
  final Duration? duration;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'deviceId': deviceId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'platform': platform,
        'appVersion': appVersion,
        'screens': screens,
        'eventCount': eventCount,
        'duration': duration?.inSeconds,
      };

  /// Проверить, активна ли сессия
  bool get isActive => endTime == null;

  /// Получить продолжительность сессии
  Duration get sessionDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  /// Получить количество уникальных экранов
  int get uniqueScreenCount => screens.toSet().length;

  @override
  String toString() =>
      'UserSession(sessionId: $sessionId, userId: $userId, eventCount: $eventCount)';
}
