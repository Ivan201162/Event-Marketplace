import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist.dart';
import '../models/specialist_tip.dart';
import '../services/specialist_service.dart';

/// Сервис для работы с рекомендациями специалистам
class SpecialistTipsService {
  static const String _tipsCollection = 'specialistTips';
  static const String _statsCollection = 'profileStats';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SpecialistService _specialistService = SpecialistService();

  /// Получить рекомендации для специалиста
  Future<List<SpecialistTip>> getSpecialistTips(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_tipsCollection)
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(SpecialistTip.fromFirestore).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения рекомендаций: $e');
      return [];
    }
  }

  /// Сгенерировать рекомендации для специалиста
  Future<List<SpecialistTip>> generateTipsForSpecialist(String userId) async {
    try {
      // Получаем профиль специалиста
      final specialist = await _specialistService.getSpecialistById(userId);
      if (specialist == null) {
        return [];
      }

      final tips = <SpecialistTip>[];
      final now = DateTime.now();

      // Анализируем профиль и генерируем рекомендации
      await _analyzeProfile(specialist, tips, now);

      // Сохраняем рекомендации
      for (final tip in tips) {
        await _firestore
            .collection(_tipsCollection)
            .doc(tip.id)
            .set(tip.toFirestore());
      }

      // Обновляем статистику профиля
      await _updateProfileStats(userId, specialist);

      return tips;
    } on Exception catch (e) {
      debugPrint('Ошибка генерации рекомендаций: $e');
      return [];
    }
  }

  /// Анализ профиля специалиста
  Future<void> _analyzeProfile(
    Specialist specialist,
    List<SpecialistTip> tips,
    DateTime now,
  ) async {
    // Проверка имени
    if (specialist.name.isEmpty || specialist.name.length < 2) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_name_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.name.value,
          title: 'Добавьте полное имя',
          message: 'Укажите ваше полное имя для лучшего доверия клиентов',
          action: 'Исправить',
          actionRoute: '/profile/edit',
          priority: TipPriority.high,
          createdAt: now,
        ),
      );
    }

    // Проверка описания
    if (specialist.description.isEmpty || specialist.description.length < 50) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_description_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.description.value,
          title: 'Расширьте описание',
          message:
              'Добавьте подробное описание ваших услуг и опыта работы (минимум 50 символов)',
          action: 'Дополнить',
          actionRoute: '/profile/edit',
          priority: TipPriority.high,
          createdAt: now,
        ),
      );
    }

    // Проверка цен
    if (specialist.price <= 0) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_price_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.price.value,
          title: 'Укажите цены',
          message:
              'Добавьте диапазон цен, чтобы клиенты могли сравнить предложения',
          action: 'Указать цены',
          actionRoute: '/profile/pricing',
          priority: TipPriority.critical,
          createdAt: now,
        ),
      );
    }

    // Проверка портфолио
    if (specialist.portfolioImages.isEmpty) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_portfolio_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.portfolio.value,
          title: 'Добавьте портфолио',
          message:
              'Загрузите 3-5 лучших работ для демонстрации вашего мастерства',
          action: 'Загрузить фото',
          actionRoute: '/profile/portfolio',
          priority: TipPriority.critical,
          createdAt: now,
        ),
      );
    } else if (specialist.portfolioImages.length < 3) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_portfolio_more_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.portfolio.value,
          title: 'Дополните портфолио',
          message:
              'Добавьте еще ${3 - specialist.portfolioImages.length} фото для лучшего представления работ',
          action: 'Добавить фото',
          actionRoute: '/profile/portfolio',
          priority: TipPriority.medium,
          createdAt: now,
        ),
      );
    }

    // Проверка доступности
    if (specialist.availableDates.isEmpty) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_availability_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.availability.value,
          title: 'Укажите доступность',
          message:
              'Добавьте свободные даты в календарь для привлечения клиентов',
          action: 'Настроить календарь',
          actionRoute: '/profile/calendar',
          priority: TipPriority.high,
          createdAt: now,
        ),
      );
    }

    // Проверка контактов
    if (specialist.phone.isEmpty && specialist.email.isEmpty) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_contact_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.contact.value,
          title: 'Добавьте контакты',
          message: 'Укажите телефон или email для связи с клиентами',
          action: 'Добавить контакты',
          actionRoute: '/profile/contact',
          priority: TipPriority.critical,
          createdAt: now,
        ),
      );
    }

    // Проверка верификации
    if (!specialist.isVerified) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_verification_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.verification.value,
          title: 'Пройдите верификацию',
          message: 'Подтвердите личность для повышения доверия клиентов',
          action: 'Верифицировать',
          actionRoute: '/profile/verification',
          priority: TipPriority.medium,
          createdAt: now,
        ),
      );
    }

    // Проверка отзывов
    if (specialist.reviewCount == 0) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_reviews_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.reviews.value,
          title: 'Попросите отзывы',
          message:
              'Попросите первых клиентов оставить отзывы для повышения рейтинга',
          action: 'Как получить отзывы',
          actionRoute: '/help/reviews',
          priority: TipPriority.medium,
          createdAt: now,
        ),
      );
    }

    // Проверка рейтинга
    if (specialist.rating < 4.0 && specialist.reviewCount > 0) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_rating_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.reviews.value,
          title: 'Улучшите качество услуг',
          message:
              'Ваш рейтинг ${specialist.rating.toStringAsFixed(1)}. Работайте над улучшением качества услуг',
          action: 'Советы по улучшению',
          actionRoute: '/help/quality',
          priority: TipPriority.high,
          createdAt: now,
        ),
      );
    }

    // Проверка опыта
    if (specialist.yearsOfExperience < 1) {
      tips.add(
        SpecialistTip(
          id: '${specialist.id}_experience_${now.millisecondsSinceEpoch}',
          userId: specialist.id,
          field: SpecialistField.description.value,
          title: 'Укажите опыт работы',
          message: 'Добавьте информацию о вашем опыте и образовании',
          action: 'Дополнить профиль',
          actionRoute: '/profile/edit',
          priority: TipPriority.low,
          createdAt: now,
        ),
      );
    }
  }

  /// Обновить статистику профиля
  Future<void> _updateProfileStats(String userId, Specialist specialist) async {
    try {
      const totalFields = 10; // Общее количество полей для проверки
      var completedFields = 0;
      final missingFields = <String>[];
      final weakFields = <String>[];

      // Подсчитываем заполненные поля
      if (specialist.name.isNotEmpty && specialist.name.length >= 2) {
        completedFields++;
      } else {
        missingFields.add('name');
      }

      if (specialist.description.isNotEmpty &&
          specialist.description.length >= 50) {
        completedFields++;
      } else {
        missingFields.add('description');
      }

      if (specialist.price > 0) {
        completedFields++;
      } else {
        missingFields.add('price');
      }

      if (specialist.portfolioImages.isNotEmpty) {
        completedFields++;
        if (specialist.portfolioImages.length < 3) {
          weakFields.add('portfolio');
        }
      } else {
        missingFields.add('portfolio');
      }

      if (specialist.availableDates.isNotEmpty) {
        completedFields++;
      } else {
        missingFields.add('availability');
      }

      if (specialist.phone.isNotEmpty || specialist.email.isNotEmpty) {
        completedFields++;
      } else {
        missingFields.add('contact');
      }

      if (specialist.isVerified) {
        completedFields++;
      } else {
        missingFields.add('verification');
      }

      if (specialist.reviewCount > 0) {
        completedFields++;
        if (specialist.rating < 4.0) {
          weakFields.add('reviews');
        }
      } else {
        missingFields.add('reviews');
      }

      if (specialist.yearsOfExperience > 0) {
        completedFields++;
      } else {
        missingFields.add('experience');
      }

      if (specialist.category.value.isNotEmpty) {
        completedFields++;
      } else {
        missingFields.add('category');
      }

      final completionPercentage =
          ((completedFields / totalFields) * 100).round();

      final stats = ProfileStats(
        userId: userId,
        completionPercentage: completionPercentage,
        totalFields: totalFields,
        completedFields: completedFields,
        missingFields: missingFields,
        weakFields: weakFields,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_statsCollection)
          .doc(userId)
          .set(stats.toFirestore());
    } on Exception catch (e) {
      debugPrint('Ошибка обновления статистики профиля: $e');
    }
  }

  /// Получить статистику профиля
  Future<ProfileStats?> getProfileStats(String userId) async {
    try {
      final doc =
          await _firestore.collection(_statsCollection).doc(userId).get();

      if (doc.exists) {
        return ProfileStats.fromFirestore(doc);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка получения статистики профиля: $e');
      return null;
    }
  }

  /// Отметить совет как выполненный
  Future<bool> markTipAsCompleted(String tipId) async {
    try {
      await _firestore.collection(_tipsCollection).doc(tipId).update({
        'isCompleted': true,
        'completedAt': Timestamp.now(),
      });
      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка отметки совета как выполненного: $e');
      return false;
    }
  }

  /// Удалить совет
  Future<bool> deleteTip(String tipId) async {
    try {
      await _firestore.collection(_tipsCollection).doc(tipId).delete();
      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка удаления совета: $e');
      return false;
    }
  }

  /// Получить общую статистику по рекомендациям
  Future<Map<String, dynamic>> getTipsStatistics(String userId) async {
    try {
      final tips = await getSpecialistTips(userId);
      final stats = await getProfileStats(userId);

      final priorityCounts = <String, int>{};
      final fieldCounts = <String, int>{};

      for (final tip in tips) {
        priorityCounts[tip.priority.value] =
            (priorityCounts[tip.priority.value] ?? 0) + 1;
        fieldCounts[tip.field] = (fieldCounts[tip.field] ?? 0) + 1;
      }

      return {
        'totalTips': tips.length,
        'priorityCounts': priorityCounts,
        'fieldCounts': fieldCounts,
        'profileStats': stats,
        'criticalTips':
            tips.where((t) => t.priority == TipPriority.critical).length,
        'highPriorityTips':
            tips.where((t) => t.priority == TipPriority.high).length,
      };
    } on Exception catch (e) {
      debugPrint('Ошибка получения статистики рекомендаций: $e');
      return {};
    }
  }

  /// Очистить старые выполненные советы
  Future<int> cleanupOldCompletedTips() async {
    try {
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      final querySnapshot = await _firestore
          .collection(_tipsCollection)
          .where('isCompleted', isEqualTo: true)
          .where('completedAt', isLessThan: Timestamp.fromDate(monthAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        debugPrint(
          'Удалено ${querySnapshot.docs.length} старых выполненных советов',
        );
      }

      return querySnapshot.docs.length;
    } on Exception catch (e) {
      debugPrint('Ошибка очистки старых советов: $e');
      return 0;
    }
  }
}
