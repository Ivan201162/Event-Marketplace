import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель профиля ведущего мероприятия
class HostProfile {
  const HostProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    required this.city,
    required this.eventCategories,
    required this.priceRange,
    required this.about,
    required this.rating,
    required this.totalReviews,
    required this.reviews,
    required this.availableDates,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HostProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return HostProfile(
      id: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      city: data['city'] as String? ?? '',
      eventCategories: List<String>.from((data['eventCategories'] as List<dynamic>?) ?? []),
      priceRange: PriceRange.fromMap(
        Map<String, dynamic>.from(
          (data['priceRange'] as Map<dynamic, dynamic>?) ?? {},
        ),
      ),
      about: data['about'] as String? ?? '',
      rating: (data['rating'] as num? ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] as int? ?? 0,
      reviews: (data['reviews'] as List<dynamic>?)
              ?.map((review) => Review.fromMap(review as Map<String, dynamic>))
              .toList() ??
          [],
      availableDates: (data['availableDates'] as List<dynamic>?)
              ?.map((date) => (date as Timestamp).toDate())
              .toList() ??
          [],
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String city;
  final List<String> eventCategories;
  final PriceRange priceRange;
  final String about;
  final double rating;
  final int totalReviews;
  final List<Review> reviews;
  final List<DateTime> availableDates;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName';

  String get displayName => '$firstName $lastName';

  String get priceRangeText =>
      'от ${priceRange.minPrice.toStringAsFixed(0)} ₽ до ${priceRange.maxPrice.toStringAsFixed(0)} ₽';

  Map<String, dynamic> toFirestore() => {
        'firstName': firstName,
        'lastName': lastName,
        'photoUrl': photoUrl,
        'city': city,
        'eventCategories': eventCategories,
        'priceRange': priceRange.toMap(),
        'about': about,
        'rating': rating,
        'totalReviews': totalReviews,
        'reviews': reviews.map((review) => review.toMap()).toList(),
        'availableDates': availableDates.map(Timestamp.fromDate).toList(),
        'isVerified': isVerified,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  HostProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? city,
    List<String>? eventCategories,
    PriceRange? priceRange,
    String? about,
    double? rating,
    int? totalReviews,
    List<Review>? reviews,
    List<DateTime>? availableDates,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      HostProfile(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        photoUrl: photoUrl ?? this.photoUrl,
        city: city ?? this.city,
        eventCategories: eventCategories ?? this.eventCategories,
        priceRange: priceRange ?? this.priceRange,
        about: about ?? this.about,
        rating: rating ?? this.rating,
        totalReviews: totalReviews ?? this.totalReviews,
        reviews: reviews ?? this.reviews,
        availableDates: availableDates ?? this.availableDates,
        isVerified: isVerified ?? this.isVerified,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Модель ценового диапазона
class PriceRange {
  const PriceRange({
    required this.minPrice,
    required this.maxPrice,
    this.currency = 'RUB',
  });

  factory PriceRange.fromMap(Map<String, dynamic> map) => PriceRange(
        minPrice: (map['minPrice'] as num? ?? 0.0).toDouble(),
        maxPrice: (map['maxPrice'] as num? ?? 0.0).toDouble(),
        currency: map['currency'] as String? ?? 'RUB',
      );
  final double minPrice;
  final double maxPrice;
  final String currency;

  Map<String, dynamic> toMap() => {
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'currency': currency,
      };
}

/// Модель отзыва
class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.eventType,
  });

  factory Review.fromMap(Map<String, dynamic> map) => Review(
        id: map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        userName: map['userName'] as String? ?? '',
        userPhotoUrl: map['userPhotoUrl'] as String?,
        rating: (map['rating'] as num? ?? 0.0).toDouble(),
        comment: map['comment'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        eventType: map['eventType'] as String? ?? '',
      );
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String eventType;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
        'eventType': eventType,
      };
}

/// Категории мероприятий
enum EventCategory {
  wedding('Свадьбы', '💒'),
  anniversary('Юбилеи', '🎂'),
  corporate('Корпоративы', '🏢'),
  birthday('Дни рождения', '🎉'),
  graduation('Выпускные', '🎓'),
  children('Детские праздники', '🎈'),
  newYear('Новогодние', '🎄'),
  other('Другие', '🎊');

  const EventCategory(this.displayName, this.emoji);

  final String displayName;
  final String emoji;
}

/// Mock данные для тестирования
class MockHostData {
  static HostProfile get sampleHost => HostProfile(
        id: 'host_001',
        firstName: 'Алексей',
        lastName: 'Смирнов',
        photoUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        city: 'Москва',
        eventCategories: [
          EventCategory.wedding.displayName,
          EventCategory.anniversary.displayName,
          EventCategory.corporate.displayName,
          EventCategory.birthday.displayName,
        ],
        priceRange: const PriceRange(
          minPrice: 15000,
          maxPrice: 35000,
        ),
        about:
            'Профессиональный ведущий с 8-летним опытом работы. Специализируюсь на свадебных церемониях и корпоративных мероприятиях. Создаю незабываемую атмосферу для вашего праздника, учитывая все пожелания и особенности мероприятия. Имею музыкальное образование и опыт работы с различными возрастными группами.',
        rating: 4.8,
        totalReviews: 127,
        reviews: MockHostData.sampleReviews,
        availableDates: MockHostData.sampleAvailableDates,
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      );

  static List<Review> get sampleReviews => [
        Review(
          id: 'review_001',
          userId: 'user_001',
          userName: 'Анна Петрова',
          userPhotoUrl:
              'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop&crop=face',
          rating: 5,
          comment:
              'Алексей - потрясающий ведущий! Наша свадьба прошла идеально. Он умеет создать атмосферу и держать внимание гостей. Очень рекомендую!',
          createdAt: DateTime(2024, 11, 15),
          eventType: 'Свадьба',
        ),
        Review(
          id: 'review_002',
          userId: 'user_002',
          userName: 'Михаил Козлов',
          userPhotoUrl:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face',
          rating: 4.5,
          comment:
              'Отличный ведущий для корпоратива! Все сотрудники остались довольны. Алексей умеет работать с любой аудиторией.',
          createdAt: DateTime(2024, 10, 28),
          eventType: 'Корпоратив',
        ),
        Review(
          id: 'review_003',
          userId: 'user_003',
          userName: 'Елена Волкова',
          userPhotoUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face',
          rating: 5,
          comment:
              'Ведущий с большой буквы! Организовал юбилей моих родителей на высшем уровне. Все гости до сих пор вспоминают этот вечер.',
          createdAt: DateTime(2024, 9, 12),
          eventType: 'Юбилей',
        ),
      ];

  static List<DateTime> get sampleAvailableDates => [
        DateTime.now().add(const Duration(days: 7)),
        DateTime.now().add(const Duration(days: 14)),
        DateTime.now().add(const Duration(days: 21)),
        DateTime.now().add(const Duration(days: 28)),
        DateTime.now().add(const Duration(days: 35)),
        DateTime.now().add(const Duration(days: 42)),
        DateTime.now().add(const Duration(days: 49)),
        DateTime.now().add(const Duration(days: 56)),
      ];
}
