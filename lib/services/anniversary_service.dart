import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder.dart';
import 'reminder_service.dart';

/// Модель годовщины
class Anniversary {
  const Anniversary({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.type,
    this.description,
    this.isRecurring = true,
    this.reminderDays = const [7, 1], // За неделю и за день
    required this.createdAt,
    this.updatedAt,
  });

  /// Создать годовщину из документа Firestore
  factory Anniversary.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Anniversary(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: AnniversaryType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AnniversaryType.custom,
      ),
      description: data['description'] as String?,
      isRecurring: data['isRecurring'] as bool? ?? true,
      reminderDays: List<int>.from(data['reminderDays'] as List<dynamic>? ?? [7, 1]),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final AnniversaryType type;
  final String? description;
  final bool isRecurring;
  final List<int> reminderDays; // Дни до годовщины для напоминаний
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'date': Timestamp.fromDate(date),
    'type': type.name,
    'description': description,
    'isRecurring': isRecurring,
    'reminderDays': reminderDays,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  /// Создать копию с изменениями
  Anniversary copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    AnniversaryType? type,
    String? description,
    bool? isRecurring,
    List<int>? reminderDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Anniversary(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    date: date ?? this.date,
    type: type ?? this.type,
    description: description ?? this.description,
    isRecurring: isRecurring ?? this.isRecurring,
    reminderDays: reminderDays ?? this.reminderDays,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Получить дату годовщины в текущем году
  DateTime getAnniversaryDateForYear(int year) => DateTime(year, date.month, date.day);

  /// Проверить, является ли дата годовщиной
  bool isAnniversaryDate(DateTime checkDate) =>
      checkDate.month == date.month && checkDate.day == date.day;

  /// Получить количество лет с даты
  int getYearsSince(DateTime fromDate) => fromDate.year - date.year;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Anniversary && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Anniversary(id: $id, title: $title, date: $date)';
}

/// Типы годовщин
enum AnniversaryType {
  wedding, // Свадьба
  birthday, // День рождения
  engagement, // Помолвка
  firstDate, // Первое свидание
  graduation, // Выпускной
  custom, // Пользовательская
}

/// Сервис для управления годовщинами
class AnniversaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReminderService _reminderService = ReminderService();

  /// Добавить годовщину
  Future<String> addAnniversary({
    required String userId,
    required String title,
    required DateTime date,
    required AnniversaryType type,
    String? description,
    bool isRecurring = true,
    List<int> reminderDays = const [7, 1],
  }) async {
    try {
      final anniversary = Anniversary(
        id: '', // Будет установлен Firestore
        userId: userId,
        title: title,
        date: date,
        type: type,
        description: description,
        isRecurring: isRecurring,
        reminderDays: reminderDays,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('anniversaries').add(anniversary.toMap());

      // Создаем напоминания для текущего года
      await _createAnniversaryReminders(anniversary.copyWith(id: docRef.id));

      return docRef.id;
    } on Exception catch (e) {
      throw Exception('Ошибка добавления годовщины: $e');
    }
  }

  /// Получить годовщины пользователя
  Future<List<Anniversary>> getUserAnniversaries(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('anniversaries')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs.map(Anniversary.fromDocument).toList();
    } on Exception catch (e) {
      throw Exception('Ошибка получения годовщин: $e');
    }
  }

  /// Получить годовщины на определенную дату
  Future<List<Anniversary>> getAnniversariesForDate(DateTime date) async {
    try {
      final querySnapshot = await _firestore
          .collection('anniversaries')
          .where('isRecurring', isEqualTo: true)
          .get();

      final anniversaries = querySnapshot.docs
          .map(Anniversary.fromDocument)
          .where((anniversary) => anniversary.isAnniversaryDate(date))
          .toList();

      return anniversaries;
    } on Exception catch (e) {
      throw Exception('Ошибка получения годовщин на дату: $e');
    }
  }

  /// Получить предстоящие годовщины
  Future<List<Anniversary>> getUpcomingAnniversaries(String userId, {int daysAhead = 30}) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: daysAhead));

      final anniversaries = await getUserAnniversaries(userId);
      final upcoming = <Anniversary>[];

      for (final anniversary in anniversaries) {
        if (!anniversary.isRecurring) continue;

        // Проверяем годовщины в текущем году
        final currentYearDate = anniversary.getAnniversaryDateForYear(now.year);
        if (currentYearDate.isAfter(now) && currentYearDate.isBefore(endDate)) {
          upcoming.add(anniversary);
        }

        // Проверяем годовщины в следующем году (если текущая дата близко к концу года)
        if (now.month == 12 && now.day > 25) {
          final nextYearDate = anniversary.getAnniversaryDateForYear(now.year + 1);
          if (nextYearDate.isBefore(endDate)) {
            upcoming.add(anniversary);
          }
        }
      }

      // Сортируем по дате
      upcoming.sort((a, b) {
        final aDate = a.getAnniversaryDateForYear(now.year);
        final bDate = b.getAnniversaryDateForYear(now.year);
        return aDate.compareTo(bDate);
      });

      return upcoming;
    } on Exception catch (e) {
      throw Exception('Ошибка получения предстоящих годовщин: $e');
    }
  }

  /// Обновить годовщину
  Future<void> updateAnniversary(String anniversaryId, Anniversary updatedAnniversary) async {
    try {
      await _firestore
          .collection('anniversaries')
          .doc(anniversaryId)
          .update(updatedAnniversary.copyWith(updatedAt: DateTime.now()).toMap());

      // Обновляем напоминания
      await _updateAnniversaryReminders(updatedAnniversary);
    } on Exception catch (e) {
      throw Exception('Ошибка обновления годовщины: $e');
    }
  }

  /// Удалить годовщину
  Future<void> deleteAnniversary(String anniversaryId) async {
    try {
      // Получаем годовщину для удаления связанных напоминаний
      final doc = await _firestore.collection('anniversaries').doc(anniversaryId).get();
      if (doc.exists) {
        final anniversary = Anniversary.fromDocument(doc);

        // Удаляем связанные напоминания
        await _deleteAnniversaryReminders(anniversary);
      }

      await _firestore.collection('anniversaries').doc(anniversaryId).delete();
    } on Exception catch (e) {
      throw Exception('Ошибка удаления годовщины: $e');
    }
  }

  /// Обработать годовщины на сегодня
  Future<void> processTodayAnniversaries() async {
    try {
      final today = DateTime.now();
      final anniversaries = await getAnniversariesForDate(today);

      for (final anniversary in anniversaries) {
        // Создаем напоминание о годовщине
        await _reminderService.createAnniversaryReminder(
          userId: anniversary.userId,
          anniversaryTitle: anniversary.title,
          anniversaryDate: today,
          isRecurring: anniversary.isRecurring,
        );

        // Создаем напоминания на следующий год
        if (anniversary.isRecurring) {
          final nextYearDate = anniversary.getAnniversaryDateForYear(today.year + 1);
          await _createAnniversaryReminders(anniversary, targetDate: nextYearDate);
        }
      }
    } on Exception catch (e) {
      throw Exception('Ошибка обработки годовщин на сегодня: $e');
    }
  }

  /// Создать напоминания для годовщины
  Future<void> _createAnniversaryReminders(Anniversary anniversary, {DateTime? targetDate}) async {
    try {
      final anniversaryDate =
          targetDate ?? anniversary.getAnniversaryDateForYear(DateTime.now().year);

      for (final daysBefore in anniversary.reminderDays) {
        final reminderDate = anniversaryDate.subtract(Duration(days: daysBefore));

        // Создаем напоминание только если дата в будущем
        if (reminderDate.isAfter(DateTime.now())) {
          await _reminderService.createAnniversaryReminder(
            userId: anniversary.userId,
            anniversaryTitle: anniversary.title,
            anniversaryDate: anniversaryDate,
            isRecurring: anniversary.isRecurring,
          );
        }
      }
    } on Exception catch (e) {
      debugPrint('Ошибка создания напоминаний для годовщины: $e');
    }
  }

  /// Обновить напоминания для годовщины
  Future<void> _updateAnniversaryReminders(Anniversary anniversary) async {
    try {
      // Удаляем старые напоминания
      await _deleteAnniversaryReminders(anniversary);

      // Создаем новые напоминания
      await _createAnniversaryReminders(anniversary);
    } on Exception catch (e) {
      debugPrint('Ошибка обновления напоминаний для годовщины: $e');
    }
  }

  /// Удалить напоминания для годовщины
  Future<void> _deleteAnniversaryReminders(Anniversary anniversary) async {
    try {
      // Находим и удаляем связанные напоминания
      final querySnapshot = await _firestore
          .collection('reminders')
          .where('userId', isEqualTo: anniversary.userId)
          .where('type', isEqualTo: ReminderType.anniversary.name)
          .where('anniversaryDate', isEqualTo: Timestamp.fromDate(anniversary.date))
          .get();

      for (final doc in querySnapshot.docs) {
        await _reminderService.deleteReminder(doc.id);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка удаления напоминаний для годовщины: $e');
    }
  }

  /// Получить статистику годовщин пользователя
  Future<Map<String, int>> getAnniversaryStats(String userId) async {
    try {
      final anniversaries = await getUserAnniversaries(userId);

      var total = 0;
      var recurring = 0;
      var upcoming = 0;
      final typeCounts = <AnniversaryType, int>{};

      final now = DateTime.now();
      final nextMonth = now.add(const Duration(days: 30));

      for (final anniversary in anniversaries) {
        total++;

        if (anniversary.isRecurring) {
          recurring++;
        }

        // Проверяем, есть ли годовщина в ближайший месяц
        final currentYearDate = anniversary.getAnniversaryDateForYear(now.year);
        if (currentYearDate.isAfter(now) && currentYearDate.isBefore(nextMonth)) {
          upcoming++;
        }

        // Подсчитываем по типам
        typeCounts[anniversary.type] = (typeCounts[anniversary.type] ?? 0) + 1;
      }

      return {
        'total': total,
        'recurring': recurring,
        'upcoming': upcoming,
        ...typeCounts.map((type, count) => MapEntry(type.name, count)),
      };
    } on Exception catch (e) {
      throw Exception('Ошибка получения статистики годовщин: $e');
    }
  }

  /// Получить название типа годовщины
  String getAnniversaryTypeName(AnniversaryType type) {
    switch (type) {
      case AnniversaryType.wedding:
        return 'Свадьба';
      case AnniversaryType.birthday:
        return 'День рождения';
      case AnniversaryType.engagement:
        return 'Помолвка';
      case AnniversaryType.firstDate:
        return 'Первое свидание';
      case AnniversaryType.graduation:
        return 'Выпускной';
      case AnniversaryType.custom:
        return 'Пользовательская';
    }
  }

  /// Получить иконку для типа годовщины
  String getAnniversaryTypeIcon(AnniversaryType type) {
    switch (type) {
      case AnniversaryType.wedding:
        return '💒';
      case AnniversaryType.birthday:
        return '🎂';
      case AnniversaryType.engagement:
        return '💍';
      case AnniversaryType.firstDate:
        return '💕';
      case AnniversaryType.graduation:
        return '🎓';
      case AnniversaryType.custom:
        return '📅';
    }
  }
}
