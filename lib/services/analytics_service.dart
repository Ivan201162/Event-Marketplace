import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с аналитикой Firebase и локальной статистикой
class AnalyticsService {
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  static final AnalyticsService _instance = AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Логирование события входа пользователя
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method ?? 'email');
      await _logCustomEvent('login', {
        'method': method ?? 'email',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка логирования входа: $e');
    }
  }

  /// Логирование события выхода пользователя
  Future<void> logLogout() async {
    try {
      await _analytics.logEvent(name: 'logout');
      await _logCustomEvent('logout', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка логирования выхода: $e');
    }
  }

  /// Логирование просмотра профиля специалиста
  Future<void> logViewProfile(
    String specialistId,
    String specialistName,
  ) async {
    try {
      await _analytics.logEvent(
        name: 'view_item',
        parameters: {
          'item_id': specialistId,
          'item_name': specialistName,
          'item_category': 'specialist_profile',
        },
      );
      await _logCustomEvent('view_profile', {
        'specialist_id': specialistId,
        'specialist_name': specialistName,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Обновляем статистику просмотров профиля
      await _updateProfileViews(specialistId);
    } on Exception catch (e) {
      debugPrint('Ошибка логирования просмотра профиля: $e');
    }
  }

  /// Логирование создания заявки
  Future<void> logCreateRequest(
    String requestId,
    String specialistId,
    String category,
  ) async {
    try {
      await _analytics.logEvent(
        name: 'create_request',
        parameters: {
          'request_id': requestId,
          'specialist_id': specialistId,
          'category': category,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      await _logCustomEvent('create_request', {
        'request_id': requestId,
        'specialist_id': specialistId,
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Обновляем статистику заявок
      await _updateRequestStats(specialistId, 'received');
    } on Exception catch (e) {
      debugPrint('Ошибка логирования создания заявки: $e');
    }
  }

  /// Логирование отправки сообщения
  Future<void> logSendMessage(String chatId, String recipientId) async {
    try {
      await _analytics.logEvent(
        name: 'send_message',
        parameters: {
          'chat_id': chatId,
          'recipient_id': recipientId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      await _logCustomEvent('send_message', {
        'chat_id': chatId,
        'recipient_id': recipientId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Обновляем статистику сообщений
      await _updateMessageStats(recipientId);
    } on Exception catch (e) {
      debugPrint('Ошибка логирования отправки сообщения: $e');
    }
  }

  /// Логирование лайка поста/идеи
  Future<void> logLikePost(String postId, String postType) async {
    try {
      await _analytics.logEvent(
        name: 'like_post',
        parameters: {
          'post_id': postId,
          'post_type': postType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      await _logCustomEvent('like_post', {
        'post_id': postId,
        'post_type': postType,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка логирования лайка: $e');
    }
  }

  /// Логирование комментария к посту/идее
  Future<void> logCommentPost(String postId, String postType) async {
    try {
      await _analytics.logEvent(
        name: 'comment_post',
        parameters: {
          'post_id': postId,
          'post_type': postType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      await _logCustomEvent('comment_post', {
        'post_id': postId,
        'post_type': postType,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка логирования комментария: $e');
    }
  }

  /// Логирование сохранения поста/идеи
  Future<void> logSavePost(String postId, String postType) async {
    try {
      await _analytics.logEvent(
        name: 'save_post',
        parameters: {
          'post_id': postId,
          'post_type': postType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      await _logCustomEvent('save_post', {
        'post_id': postId,
        'post_type': postType,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка логирования сохранения: $e');
    }
  }

  /// Логирование открытия настроек
  Future<void> logOpenSettings() async {
    try {
      await _analytics.logEvent(name: 'open_settings');
      await _logCustomEvent('open_settings', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка логирования открытия настроек: $e');
    }
  }

  /// Логирование изменения темы
  Future<void> logChangeTheme(String theme) async {
    try {
      await _analytics.logEvent(
        name: 'change_theme',
        parameters: {'theme': theme},
      );
      await _logCustomEvent('change_theme', {
        'theme': theme,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка логирования изменения темы: $e');
    }
  }

  /// Логирование переключения уведомлений
  Future<void> logToggleNotifications(bool enabled) async {
    try {
      await _analytics.logEvent(
        name: 'toggle_notifications',
        parameters: {'enabled': enabled},
      );
      await _logCustomEvent('toggle_notifications', {
        'enabled': enabled,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка логирования переключения уведомлений: $e');
    }
  }

  /// Логирование просмотра экрана
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } on Exception catch (e) {
      debugPrint('Ошибка логирования просмотра экрана: $e');
    }
  }

  /// Логирование пользовательского события
  Future<void> _logCustomEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('analytics_events').add({
          'event_name': eventName,
          'user_id': user.uid,
          'parameters': parameters,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения пользовательского события: $e');
    }
  }

  /// Обновление статистики просмотров профиля
  Future<void> _updateProfileViews(String specialistId) async {
    try {
      await _firestore.collection('userStats').doc(specialistId).set(
        {
          'userId': specialistId,
          'views': FieldValue.increment(1),
          'lastViewDate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка обновления статистики просмотров: $e');
    }
  }

  /// Обновление статистики заявок
  Future<void> _updateRequestStats(String specialistId, String type) async {
    try {
      final field = type == 'received' ? 'requests' : 'rejected_requests';
      await _firestore.collection('userStats').doc(specialistId).set(
        {
          'userId': specialistId,
          field: FieldValue.increment(1),
          'lastRequestDate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка обновления статистики заявок: $e');
    }
  }

  /// Обновление статистики сообщений
  Future<void> _updateMessageStats(String userId) async {
    try {
      await _firestore.collection('userStats').doc(userId).set(
        {
          'userId': userId,
          'messages': FieldValue.increment(1),
          'lastMessageDate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка обновления статистики сообщений: $e');
    }
  }

  /// Получение статистики пользователя
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('userStats').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка получения статистики пользователя: $e');
      return null;
    }
  }

  /// Получение аналитических отчётов для админов
  Future<Map<String, dynamic>> getAnalyticsReports() async {
    try {
      final doc =
          await _firestore.collection('analyticsReports').doc('main').get();
      if (doc.exists) {
        return doc.data()!;
      }
      return {};
    } on Exception catch (e) {
      debugPrint('Ошибка получения аналитических отчётов: $e');
      return {};
    }
  }

  /// Обновление аналитических отчётов
  Future<void> updateAnalyticsReports() async {
    try {
      // Получаем топ специалистов
      final specialistsQuery = await _firestore
          .collection('userStats')
          .orderBy('views', descending: true)
          .limit(10)
          .get();

      final topSpecialists = specialistsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'views': data['views'] ?? 0,
          'requests': data['requests'] ?? 0,
          'messages': data['messages'] ?? 0,
        };
      }).toList();

      // Получаем топ заказчиков
      final customersQuery = await _firestore
          .collection('analytics_events')
          .where('event_name', isEqualTo: 'create_request')
          .get();

      final customerStats = <String, int>{};
      for (final doc in customersQuery.docs) {
        final data = doc.data();
        final userId = data['user_id'] as String?;
        if (userId != null) {
          customerStats[userId] = (customerStats[userId] ?? 0) + 1;
        }
      }

      final topCustomers = customerStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCustomersList = topCustomers
          .take(10)
          .map(
            (entry) => {
              'userId': entry.key,
              'requests': entry.value,
            },
          )
          .toList();

      // Получаем популярные категории
      final categoriesQuery = await _firestore
          .collection('analytics_events')
          .where('event_name', isEqualTo: 'create_request')
          .get();

      final categoryStats = <String, int>{};
      for (final doc in categoriesQuery.docs) {
        final data = doc.data();
        final parameters = data['parameters'] as Map<String, dynamic>?;
        final category = parameters?['category'] as String?;
        if (category != null) {
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;
        }
      }

      final popularCategories = categoryStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final popularCategoriesList = popularCategories
          .take(5)
          .map(
            (entry) => {
              'category': entry.key,
              'count': entry.value,
            },
          )
          .toList();

      // Сохраняем отчёт
      await _firestore.collection('analyticsReports').doc('main').set({
        'topSpecialists': topSpecialists,
        'topCustomers': topCustomersList,
        'popularCategories': popularCategoriesList,
        'dateGenerated': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка обновления аналитических отчётов: $e');
    }
  }
}
