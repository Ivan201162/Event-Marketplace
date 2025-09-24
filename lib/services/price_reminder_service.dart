import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist.dart';

/// Сервис для напоминаний об обновлении цен
class PriceReminderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Создать напоминание об обновлении цен
  Future<PriceReminder> createPriceReminder({
    required String specialistId,
    required PriceReminderType type,
    required DateTime scheduledDate,
    String? message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final reminder = PriceReminder(
        id: _generateReminderId(),
        specialistId: specialistId,
        type: type,
        status: PriceReminderStatus.scheduled,
        scheduledDate: scheduledDate,
        message: message ?? _getDefaultMessage(type),
        metadata: metadata ?? {},
        createdAt: DateTime.now(),
      );

      await _db.collection('price_reminders').doc(reminder.id).set(reminder.toMap());
      return reminder;
    } catch (e) {
      debugPrint('Ошибка создания напоминания о ценах: $e');
      throw Exception('Не удалось создать напоминание: $e');
    }
  }

  /// Создать автоматические напоминания для специалиста
  Future<List<PriceReminder>> createAutomaticReminders(String specialistId) async {
    try {
      final specialist = await _getSpecialist(specialistId);
      if (specialist == null) {
        throw Exception('Специалист не найден');
      }

      final reminders = <PriceReminder>[];

      // Напоминание о сезонном обновлении цен
      final seasonalReminder = await createPriceReminder(
        specialistId: specialistId,
        type: PriceReminderType.seasonal,
        scheduledDate: _getNextSeasonalDate(),
        metadata: {
          'season': _getCurrentSeason(),
          'autoCreated': true,
        },
      );
      reminders.add(seasonalReminder);

      // Напоминание о ежемесячном обновлении
      final monthlyReminder = await createPriceReminder(
        specialistId: specialistId,
        type: PriceReminderType.monthly,
        scheduledDate: _getNextMonthlyDate(),
        metadata: {
          'autoCreated': true,
        },
      );
      reminders.add(monthlyReminder);

      // Напоминание о проверке конкурентов
      final competitorReminder = await createPriceReminder(
        specialistId: specialistId,
        type: PriceReminderType.competitorAnalysis,
        scheduledDate: _getNextCompetitorAnalysisDate(),
        metadata: {
          'autoCreated': true,
        },
      );
      reminders.add(competitorReminder);

      return reminders;
    } catch (e) {
      debugPrint('Ошибка создания автоматических напоминаний: $e');
      return [];
    }
  }

  /// Получить активные напоминания для специалиста
  Future<List<PriceReminder>> getActiveReminders(String specialistId) async {
    try {
      final query = await _db
          .collection('price_reminders')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: PriceReminderStatus.scheduled.name)
          .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))))
          .orderBy('scheduledDate')
          .get();

      return query.docs.map((doc) => PriceReminder.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Ошибка получения активных напоминаний: $e');
      return [];
    }
  }

  /// Отметить напоминание как выполненное
  Future<void> markReminderAsCompleted({
    required String reminderId,
    required String specialistId,
    String? notes,
    Map<String, dynamic>? completionData,
  }) async {
    try {
      await _db.collection('price_reminders').doc(reminderId).update({
        'status': PriceReminderStatus.completed.name,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'notes': notes,
        'completionData': completionData ?? {},
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Создаем следующее напоминание, если это повторяющееся
      await _createNextReminderIfNeeded(reminderId, specialistId);
    } catch (e) {
      debugPrint('Ошибка отметки напоминания как выполненного: $e');
    }
  }

  /// Отложить напоминание
  Future<void> postponeReminder({
    required String reminderId,
    required Duration postponeBy,
    String? reason,
  }) async {
    try {
      final reminder = await _getReminder(reminderId);
      if (reminder == null) return;

      final newScheduledDate = reminder.scheduledDate.add(postponeBy);

      await _db.collection('price_reminders').doc(reminderId).update({
        'scheduledDate': Timestamp.fromDate(newScheduledDate),
        'postponedAt': Timestamp.fromDate(DateTime.now()),
        'postponeReason': reason,
        'postponeCount': (reminder.metadata?['postponeCount'] as int? ?? 0) + 1,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Ошибка отложения напоминания: $e');
    }
  }

  /// Получить статистику напоминаний для специалиста
  Future<PriceReminderStatistics> getReminderStatistics(String specialistId) async {
    try {
      final query = await _db
          .collection('price_reminders')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final reminders = query.docs.map((doc) => PriceReminder.fromDocument(doc)).toList();

      final totalReminders = reminders.length;
      final completedReminders = reminders.where((r) => r.status == PriceReminderStatus.completed).length;
      final pendingReminders = reminders.where((r) => r.status == PriceReminderStatus.scheduled).length;
      final overdueReminders = reminders.where((r) => 
          r.status == PriceReminderStatus.scheduled && 
          r.scheduledDate.isBefore(DateTime.now())).length;

      final completionRate = totalReminders > 0 ? (completedReminders / totalReminders) * 100 : 0;

      return PriceReminderStatistics(
        specialistId: specialistId,
        totalReminders: totalReminders,
        completedReminders: completedReminders,
        pendingReminders: pendingReminders,
        overdueReminders: overdueReminders,
        completionRate: completionRate,
        lastReminderDate: reminders.isNotEmpty 
            ? reminders.map((r) => r.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики напоминаний: $e');
      return PriceReminderStatistics.empty(specialistId);
    }
  }

  /// Получить рекомендации по ценам
  Future<PriceRecommendations> getPriceRecommendations(String specialistId) async {
    try {
      final specialist = await _getSpecialist(specialistId);
      if (specialist == null) {
        throw Exception('Специалист не найден');
      }

      final recommendations = <PriceRecommendation>[];

      // Анализ конкурентов
      final competitorAnalysis = await _analyzeCompetitors(specialist);
      if (competitorAnalysis != null) {
        recommendations.add(competitorAnalysis);
      }

      // Анализ сезонности
      final seasonalAnalysis = await _analyzeSeasonality(specialist);
      if (seasonalAnalysis != null) {
        recommendations.add(seasonalAnalysis);
      }

      // Анализ спроса
      final demandAnalysis = await _analyzeDemand(specialist);
      if (demandAnalysis != null) {
        recommendations.add(demandAnalysis);
      }

      return PriceRecommendations(
        specialistId: specialistId,
        currentPrice: specialist.price,
        recommendations: recommendations,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Ошибка получения рекомендаций по ценам: $e');
      return PriceRecommendations.empty(specialistId);
    }
  }

  /// Создать следующее напоминание, если необходимо
  Future<void> _createNextReminderIfNeeded(String completedReminderId, String specialistId) async {
    try {
      final completedReminder = await _getReminder(completedReminderId);
      if (completedReminder == null) return;

      // Создаем следующее напоминание для повторяющихся типов
      DateTime? nextScheduledDate;
      
      switch (completedReminder.type) {
        case PriceReminderType.monthly:
          nextScheduledDate = DateTime.now().add(const Duration(days: 30));
          break;
        case PriceReminderType.seasonal:
          nextScheduledDate = _getNextSeasonalDate();
          break;
        case PriceReminderType.competitorAnalysis:
          nextScheduledDate = _getNextCompetitorAnalysisDate();
          break;
        default:
          return; // Не создаем следующее напоминание для одноразовых
      }

      if (nextScheduledDate != null) {
        await createPriceReminder(
          specialistId: specialistId,
          type: completedReminder.type,
          scheduledDate: nextScheduledDate,
          metadata: {
            'autoCreated': true,
            'previousReminderId': completedReminderId,
          },
        );
      }
    } catch (e) {
      debugPrint('Ошибка создания следующего напоминания: $e');
    }
  }

  /// Получить специалиста
  Future<Specialist?> _getSpecialist(String specialistId) async {
    try {
      final doc = await _db.collection('specialists').doc(specialistId).get();
      if (doc.exists) {
        return Specialist.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения специалиста: $e');
      return null;
    }
  }

  /// Получить напоминание
  Future<PriceReminder?> _getReminder(String reminderId) async {
    try {
      final doc = await _db.collection('price_reminders').doc(reminderId).get();
      if (doc.exists) {
        return PriceReminder.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения напоминания: $e');
      return null;
    }
  }

  /// Получить дату следующего сезонного напоминания
  DateTime _getNextSeasonalDate() {
    final now = DateTime.now();
    final currentMonth = now.month;
    
    // Сезонные напоминания: март, июнь, сентябрь, декабрь
    final seasonalMonths = [3, 6, 9, 12];
    
    for (final month in seasonalMonths) {
      if (month > currentMonth) {
        return DateTime(now.year, month, 1);
      }
    }
    
    // Если все сезоны прошли, берем следующий год
    return DateTime(now.year + 1, 3, 1);
  }

  /// Получить дату следующего ежемесячного напоминания
  DateTime _getNextMonthlyDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  /// Получить дату следующего анализа конкурентов
  DateTime _getNextCompetitorAnalysisDate() {
    return DateTime.now().add(const Duration(days: 14));
  }

  /// Получить текущий сезон
  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'весна';
    if (month >= 6 && month <= 8) return 'лето';
    if (month >= 9 && month <= 11) return 'осень';
    return 'зима';
  }

  /// Получить сообщение по умолчанию
  String _getDefaultMessage(PriceReminderType type) {
    switch (type) {
      case PriceReminderType.seasonal:
        return 'Время обновить цены на новый сезон!';
      case PriceReminderType.monthly:
        return 'Ежемесячная проверка цен';
      case PriceReminderType.competitorAnalysis:
        return 'Проверьте цены конкурентов';
      case PriceReminderType.demandBased:
        return 'Анализ спроса и корректировка цен';
      case PriceReminderType.custom:
        return 'Напоминание об обновлении цен';
    }
  }

  /// Анализ конкурентов
  Future<PriceRecommendation?> _analyzeCompetitors(Specialist specialist) async {
    try {
      // В реальном приложении здесь был бы анализ цен конкурентов
      // Для демонстрации возвращаем примерную рекомендацию
      
      final currentPrice = specialist.price;
      final averageCompetitorPrice = currentPrice * 1.1; // +10% от текущей цены
      
      if (currentPrice < averageCompetitorPrice * 0.8) {
        return PriceRecommendation(
          type: PriceRecommendationType.increase,
          title: 'Цена ниже рынка',
          description: 'Ваша цена на ${(averageCompetitorPrice - currentPrice).toInt()} ₽ ниже среднерыночной',
          suggestedPrice: averageCompetitorPrice * 0.9,
          confidence: 0.8,
          reason: 'Анализ конкурентов показывает, что вы можете повысить цену',
        );
      } else if (currentPrice > averageCompetitorPrice * 1.2) {
        return PriceRecommendation(
          type: PriceRecommendationType.decrease,
          title: 'Цена выше рынка',
          description: 'Ваша цена на ${(currentPrice - averageCompetitorPrice).toInt()} ₽ выше среднерыночной',
          suggestedPrice: averageCompetitorPrice * 1.1,
          confidence: 0.7,
          reason: 'Рассмотрите возможность снижения цены для повышения конкурентоспособности',
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Ошибка анализа конкурентов: $e');
      return null;
    }
  }

  /// Анализ сезонности
  Future<PriceRecommendation?> _analyzeSeasonality(Specialist specialist) async {
    try {
      final month = DateTime.now().month;
      final currentPrice = specialist.price;
      
      // Примерные сезонные коэффициенты
      double seasonalMultiplier = 1.0;
      String season = '';
      
      if (month >= 5 && month <= 9) {
        // Летний сезон - высокий спрос
        seasonalMultiplier = 1.2;
        season = 'летний';
      } else if (month == 12 || month == 1) {
        // Новогодний сезон - очень высокий спрос
        seasonalMultiplier = 1.5;
        season = 'новогодний';
      } else if (month >= 2 && month <= 4) {
        // Низкий сезон
        seasonalMultiplier = 0.8;
        season = 'низкий';
      }
      
      if (seasonalMultiplier != 1.0) {
        final suggestedPrice = currentPrice * seasonalMultiplier;
        return PriceRecommendation(
          type: seasonalMultiplier > 1.0 ? PriceRecommendationType.increase : PriceRecommendationType.decrease,
          title: 'Сезонная корректировка',
          description: 'В $season сезон рекомендуется ${seasonalMultiplier > 1.0 ? 'повысить' : 'снизить'} цену',
          suggestedPrice: suggestedPrice,
          confidence: 0.9,
          reason: 'Сезонные колебания спроса',
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Ошибка анализа сезонности: $e');
      return null;
    }
  }

  /// Анализ спроса
  Future<PriceRecommendation?> _analyzeDemand(Specialist specialist) async {
    try {
      // В реальном приложении здесь был бы анализ заказов и спроса
      // Для демонстрации возвращаем примерную рекомендацию
      
      final currentPrice = specialist.price;
      
      // Имитируем высокий спрос
      if (specialist.rating > 4.5 && specialist.reviewCount > 50) {
        return PriceRecommendation(
          type: PriceRecommendationType.increase,
          title: 'Высокий спрос',
          description: 'Ваши услуги пользуются высоким спросом',
          suggestedPrice: currentPrice * 1.15,
          confidence: 0.8,
          reason: 'Высокий рейтинг и количество отзывов позволяют повысить цену',
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Ошибка анализа спроса: $e');
      return null;
    }
  }

  /// Генерировать ID для напоминания
  String _generateReminderId() {
    return 'reminder_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }
}

/// Типы напоминаний о ценах
enum PriceReminderType {
  seasonal,           // Сезонное обновление
  monthly,            // Ежемесячная проверка
  competitorAnalysis, // Анализ конкурентов
  demandBased,        // На основе спроса
  custom,             // Пользовательское
}

/// Статусы напоминаний
enum PriceReminderStatus {
  scheduled,  // Запланировано
  completed,  // Выполнено
  cancelled,  // Отменено
}

/// Напоминание о ценах
class PriceReminder {
  const PriceReminder({
    required this.id,
    required this.specialistId,
    required this.type,
    required this.status,
    required this.scheduledDate,
    required this.message,
    required this.metadata,
    required this.createdAt,
    this.completedAt,
    this.notes,
    this.completionData,
  });

  factory PriceReminder.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PriceReminder(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      type: PriceReminderType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PriceReminderType.custom,
      ),
      status: PriceReminderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PriceReminderStatus.scheduled,
      ),
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      message: data['message'] as String,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      notes: data['notes'] as String?,
      completionData: data['completionData'] != null 
          ? Map<String, dynamic>.from(data['completionData']) 
          : null,
    );
  }

  final String id;
  final String specialistId;
  final PriceReminderType type;
  final PriceReminderStatus status;
  final DateTime scheduledDate;
  final String message;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;
  final Map<String, dynamic>? completionData;

  Map<String, dynamic> toMap() => {
    'specialistId': specialistId,
    'type': type.name,
    'status': status.name,
    'scheduledDate': Timestamp.fromDate(scheduledDate),
    'message': message,
    'metadata': metadata,
    'createdAt': Timestamp.fromDate(createdAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'notes': notes,
    'completionData': completionData,
  };

  /// Проверить, просрочено ли напоминание
  bool get isOverdue => status == PriceReminderStatus.scheduled && scheduledDate.isBefore(DateTime.now());
}

/// Статистика напоминаний
class PriceReminderStatistics {
  const PriceReminderStatistics({
    required this.specialistId,
    required this.totalReminders,
    required this.completedReminders,
    required this.pendingReminders,
    required this.overdueReminders,
    required this.completionRate,
    this.lastReminderDate,
  });

  final String specialistId;
  final int totalReminders;
  final int completedReminders;
  final int pendingReminders;
  final int overdueReminders;
  final double completionRate;
  final DateTime? lastReminderDate;

  factory PriceReminderStatistics.empty(String specialistId) => PriceReminderStatistics(
    specialistId: specialistId,
    totalReminders: 0,
    completedReminders: 0,
    pendingReminders: 0,
    overdueReminders: 0,
    completionRate: 0,
  );
}

/// Рекомендации по ценам
class PriceRecommendations {
  const PriceRecommendations({
    required this.specialistId,
    required this.currentPrice,
    required this.recommendations,
    required this.generatedAt,
  });

  final String specialistId;
  final double currentPrice;
  final List<PriceRecommendation> recommendations;
  final DateTime generatedAt;

  factory PriceRecommendations.empty(String specialistId) => PriceRecommendations(
    specialistId: specialistId,
    currentPrice: 0,
    recommendations: [],
    generatedAt: DateTime.now(),
  );
}

/// Рекомендация по цене
class PriceRecommendation {
  const PriceRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.suggestedPrice,
    required this.confidence,
    required this.reason,
  });

  final PriceRecommendationType type;
  final String title;
  final String description;
  final double suggestedPrice;
  final double confidence; // 0.0 - 1.0
  final String reason;
}

/// Типы рекомендаций по ценам
enum PriceRecommendationType {
  increase,  // Повысить цену
  decrease,  // Снизить цену
  maintain,  // Оставить без изменений
}