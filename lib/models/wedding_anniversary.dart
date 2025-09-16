import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель годовщины свадьбы
class WeddingAnniversary {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerEmail;
  final DateTime weddingDate;
  final int yearsMarried;
  final DateTime nextAnniversary;
  final bool isActive;
  final List<String> reminderDates; // За сколько дней напоминать
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const WeddingAnniversary({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    required this.weddingDate,
    required this.yearsMarried,
    required this.nextAnniversary,
    required this.isActive,
    required this.reminderDates,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Создать из Map
  factory WeddingAnniversary.fromMap(Map<String, dynamic> data) {
    return WeddingAnniversary(
      id: data['id'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'],
      weddingDate: (data['weddingDate'] as Timestamp).toDate(),
      yearsMarried: data['yearsMarried'] ?? 0,
      nextAnniversary: (data['nextAnniversary'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      reminderDates:
          List<String>.from(data['reminderDates'] ?? ['30', '7', '1']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'weddingDate': Timestamp.fromDate(weddingDate),
      'yearsMarried': yearsMarried,
      'nextAnniversary': Timestamp.fromDate(nextAnniversary),
      'isActive': isActive,
      'reminderDates': reminderDates,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Копировать с изменениями
  WeddingAnniversary copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    DateTime? weddingDate,
    int? yearsMarried,
    DateTime? nextAnniversary,
    bool? isActive,
    List<String>? reminderDates,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return WeddingAnniversary(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      weddingDate: weddingDate ?? this.weddingDate,
      yearsMarried: yearsMarried ?? this.yearsMarried,
      nextAnniversary: nextAnniversary ?? this.nextAnniversary,
      isActive: isActive ?? this.isActive,
      reminderDates: reminderDates ?? this.reminderDates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Вычислить количество лет брака
  static int calculateYearsMarried(DateTime weddingDate) {
    final now = DateTime.now();
    int years = now.year - weddingDate.year;

    if (now.month < weddingDate.month ||
        (now.month == weddingDate.month && now.day < weddingDate.day)) {
      years--;
    }

    return years;
  }

  /// Вычислить следующую годовщину
  static DateTime calculateNextAnniversary(DateTime weddingDate) {
    final now = DateTime.now();
    int currentYear = now.year;

    // Проверяем, была ли годовщина в этом году
    final anniversaryThisYear =
        DateTime(currentYear, weddingDate.month, weddingDate.day);
    if (anniversaryThisYear.isBefore(now) ||
        anniversaryThisYear.isAtSameMomentAs(now)) {
      currentYear++;
    }

    return DateTime(currentYear, weddingDate.month, weddingDate.day);
  }

  /// Получить название годовщины
  String get anniversaryName {
    switch (yearsMarried) {
      case 1:
        return 'Бумажная свадьба';
      case 2:
        return 'Хлопковая свадьба';
      case 3:
        return 'Кожаная свадьба';
      case 4:
        return 'Льняная свадьба';
      case 5:
        return 'Деревянная свадьба';
      case 6:
        return 'Чугунная свадьба';
      case 7:
        return 'Медная свадьба';
      case 8:
        return 'Жестяная свадьба';
      case 9:
        return 'Фаянсовая свадьба';
      case 10:
        return 'Розовая свадьба';
      case 11:
        return 'Стальная свадьба';
      case 12:
        return 'Никелевая свадьба';
      case 13:
        return 'Кружевная свадьба';
      case 14:
        return 'Агатовая свадьба';
      case 15:
        return 'Хрустальная свадьба';
      case 20:
        return 'Фарфоровая свадьба';
      case 25:
        return 'Серебряная свадьба';
      case 30:
        return 'Жемчужная свадьба';
      case 35:
        return 'Коралловая свадьба';
      case 40:
        return 'Рубиновая свадьба';
      case 45:
        return 'Сапфировая свадьба';
      case 50:
        return 'Золотая свадьба';
      case 55:
        return 'Изумрудная свадьба';
      case 60:
        return 'Бриллиантовая свадьба';
      case 65:
        return 'Железная свадьба';
      case 70:
        return 'Благодатная свадьба';
      case 75:
        return 'Коронная свадьба';
      case 80:
        return 'Дубовая свадьба';
      default:
        return 'Годовщина свадьбы';
    }
  }

  /// Получить описание годовщины
  String get anniversaryDescription {
    switch (yearsMarried) {
      case 1:
        return 'Первый год совместной жизни - время узнавания друг друга';
      case 5:
        return 'Пять лет брака - отношения окрепли, семья стала крепче';
      case 10:
        return 'Десять лет брака - юбилейная дата, требующая особого внимания';
      case 25:
        return 'Серебряная свадьба - четверть века счастливой семейной жизни';
      case 50:
        return 'Золотая свадьба - полвека любви, верности и взаимопонимания';
      default:
        return 'Еще один год счастливой семейной жизни';
    }
  }

  /// Получить рекомендации для годовщины
  List<String> get anniversaryRecommendations {
    switch (yearsMarried) {
      case 1:
        return [
          'Романтический ужин в ресторане',
          'Фотосессия для молодой семьи',
          'Подарок из бумаги (книга, картина)',
        ];
      case 5:
        return [
          'Путешествие вдвоем',
          'Обновление свадебных колец',
          'Подарок из дерева (мебель, декор)',
        ];
      case 10:
        return [
          'Повторение свадебной церемонии',
          'Семейная фотосессия',
          'Подарок с розами',
        ];
      case 25:
        return [
          'Торжественный прием',
          'Обновление свадебных колец',
          'Серебряные подарки',
        ];
      case 50:
        return [
          'Большой семейный праздник',
          'Золотые подарки',
          'Повторение свадебной церемонии',
        ];
      default:
        return [
          'Романтический ужин',
          'Подарок по случаю',
          'Время вдвоем',
        ];
    }
  }
}

/// Модель напоминания о годовщине
class AnniversaryReminder {
  final String id;
  final String anniversaryId;
  final String customerId;
  final DateTime reminderDate;
  final String message;
  final bool isSent;
  final DateTime? sentAt;
  final DateTime createdAt;

  const AnniversaryReminder({
    required this.id,
    required this.anniversaryId,
    required this.customerId,
    required this.reminderDate,
    required this.message,
    required this.isSent,
    this.sentAt,
    required this.createdAt,
  });

  /// Создать из Map
  factory AnniversaryReminder.fromMap(Map<String, dynamic> data) {
    return AnniversaryReminder(
      id: data['id'] ?? '',
      anniversaryId: data['anniversaryId'] ?? '',
      customerId: data['customerId'] ?? '',
      reminderDate: (data['reminderDate'] as Timestamp).toDate(),
      message: data['message'] ?? '',
      isSent: data['isSent'] ?? false,
      sentAt: data['sentAt'] != null
          ? (data['sentAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'anniversaryId': anniversaryId,
      'customerId': customerId,
      'reminderDate': Timestamp.fromDate(reminderDate),
      'message': message,
      'isSent': isSent,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
