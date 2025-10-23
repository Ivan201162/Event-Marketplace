import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель пользовательских предпочтений для персональных рекомендаций
class UserPreferences {
  const UserPreferences({
    required this.userId,
    this.likedStyles = const [],
    this.preferredBudget = 0.0,
    this.preferredCities = const [],
    this.pastRequests = const [],
    this.favoriteCategories = const [],
    this.dislikedStyles = const [],
    this.preferredEventTypes = const [],
    this.budgetRange = const {},
    this.locationPreferences = const {},
    this.stylePreferences = const {},
    this.experiencePreferences = const {},
    this.ratingPreferences = const {},
    this.availabilityPreferences = const {},
    this.personalityPreferences = const {},
    this.searchHistory = const [],
    this.interactionHistory = const [],
    this.recommendationHistory = const [],
    this.feedbackHistory = const [],
    this.learningData = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из Map
  factory UserPreferences.fromMap(Map<String, dynamic> data) => UserPreferences(
        userId: data['userId'] as String,
        likedStyles:
            (data['likedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
        preferredBudget: (data['preferredBudget'] as num?)?.toDouble() ?? 0.0,
        preferredCities:
            (data['preferredCities'] as List<dynamic>?)?.cast<String>() ?? [],
        pastRequests:
            (data['pastRequests'] as List<dynamic>?)?.cast<String>() ?? [],
        favoriteCategories:
            (data['favoriteCategories'] as List<dynamic>?)?.cast<String>() ??
                [],
        dislikedStyles:
            (data['dislikedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
        preferredEventTypes:
            (data['preferredEventTypes'] as List<dynamic>?)?.cast<String>() ??
                [],
        budgetRange: Map<String, dynamic>.from(data['budgetRange'] ?? {}),
        locationPreferences:
            Map<String, dynamic>.from(data['locationPreferences'] ?? {}),
        stylePreferences:
            Map<String, dynamic>.from(data['stylePreferences'] ?? {}),
        experiencePreferences:
            Map<String, dynamic>.from(data['experiencePreferences'] ?? {}),
        ratingPreferences:
            Map<String, dynamic>.from(data['ratingPreferences'] ?? {}),
        availabilityPreferences:
            Map<String, dynamic>.from(data['availabilityPreferences'] ?? {}),
        personalityPreferences:
            Map<String, dynamic>.from(data['personalityPreferences'] ?? {}),
        searchHistory: (data['searchHistory'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        interactionHistory: (data['interactionHistory'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        recommendationHistory: (data['recommendationHistory'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        feedbackHistory: (data['feedbackHistory'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        learningData: Map<String, dynamic>.from(data['learningData'] ?? {}),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.parse(data['updatedAt'].toString()))
            : DateTime.now(),
      );

  /// Создать из документа Firestore
  factory UserPreferences.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserPreferences.fromMap({'userId': doc.id, ...data});
  }

  final String userId;
  final List<String> likedStyles; // Понравившиеся стили
  final double preferredBudget; // Предпочитаемый бюджет
  final List<String> preferredCities; // Предпочитаемые города
  final List<String> pastRequests; // Прошлые запросы
  final List<String> favoriteCategories; // Любимые категории
  final List<String> dislikedStyles; // Не понравившиеся стили
  final List<String> preferredEventTypes; // Предпочитаемые типы мероприятий
  final Map<String, dynamic> budgetRange; // Диапазон бюджета
  final Map<String, dynamic> locationPreferences; // Предпочтения по локации
  final Map<String, dynamic> stylePreferences; // Предпочтения по стилю
  final Map<String, dynamic> experiencePreferences; // Предпочтения по опыту
  final Map<String, dynamic> ratingPreferences; // Предпочтения по рейтингу
  final Map<String, dynamic>
      availabilityPreferences; // Предпочтения по доступности
  final Map<String, dynamic>
      personalityPreferences; // Предпочтения по характеру
  final List<Map<String, dynamic>> searchHistory; // История поиска
  final List<Map<String, dynamic>> interactionHistory; // История взаимодействий
  final List<Map<String, dynamic>>
      recommendationHistory; // История рекомендаций
  final List<Map<String, dynamic>> feedbackHistory; // История отзывов
  final Map<String, dynamic> learningData; // Данные для обучения модели
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'likedStyles': likedStyles,
        'preferredBudget': preferredBudget,
        'preferredCities': preferredCities,
        'pastRequests': pastRequests,
        'favoriteCategories': favoriteCategories,
        'dislikedStyles': dislikedStyles,
        'preferredEventTypes': preferredEventTypes,
        'budgetRange': budgetRange,
        'locationPreferences': locationPreferences,
        'stylePreferences': stylePreferences,
        'experiencePreferences': experiencePreferences,
        'ratingPreferences': ratingPreferences,
        'availabilityPreferences': availabilityPreferences,
        'personalityPreferences': personalityPreferences,
        'searchHistory': searchHistory,
        'interactionHistory': interactionHistory,
        'recommendationHistory': recommendationHistory,
        'feedbackHistory': feedbackHistory,
        'learningData': learningData,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Копировать с изменениями
  UserPreferences copyWith({
    String? userId,
    List<String>? likedStyles,
    double? preferredBudget,
    List<String>? preferredCities,
    List<String>? pastRequests,
    List<String>? favoriteCategories,
    List<String>? dislikedStyles,
    List<String>? preferredEventTypes,
    Map<String, dynamic>? budgetRange,
    Map<String, dynamic>? locationPreferences,
    Map<String, dynamic>? stylePreferences,
    Map<String, dynamic>? experiencePreferences,
    Map<String, dynamic>? ratingPreferences,
    Map<String, dynamic>? availabilityPreferences,
    Map<String, dynamic>? personalityPreferences,
    List<Map<String, dynamic>>? searchHistory,
    List<Map<String, dynamic>>? interactionHistory,
    List<Map<String, dynamic>>? recommendationHistory,
    List<Map<String, dynamic>>? feedbackHistory,
    Map<String, dynamic>? learningData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserPreferences(
        userId: userId ?? this.userId,
        likedStyles: likedStyles ?? this.likedStyles,
        preferredBudget: preferredBudget ?? this.preferredBudget,
        preferredCities: preferredCities ?? this.preferredCities,
        pastRequests: pastRequests ?? this.pastRequests,
        favoriteCategories: favoriteCategories ?? this.favoriteCategories,
        dislikedStyles: dislikedStyles ?? this.dislikedStyles,
        preferredEventTypes: preferredEventTypes ?? this.preferredEventTypes,
        budgetRange: budgetRange ?? this.budgetRange,
        locationPreferences: locationPreferences ?? this.locationPreferences,
        stylePreferences: stylePreferences ?? this.stylePreferences,
        experiencePreferences:
            experiencePreferences ?? this.experiencePreferences,
        ratingPreferences: ratingPreferences ?? this.ratingPreferences,
        availabilityPreferences:
            availabilityPreferences ?? this.availabilityPreferences,
        personalityPreferences:
            personalityPreferences ?? this.personalityPreferences,
        searchHistory: searchHistory ?? this.searchHistory,
        interactionHistory: interactionHistory ?? this.interactionHistory,
        recommendationHistory:
            recommendationHistory ?? this.recommendationHistory,
        feedbackHistory: feedbackHistory ?? this.feedbackHistory,
        learningData: learningData ?? this.learningData,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Добавить понравившийся стиль
  UserPreferences addLikedStyle(String style) {
    if (likedStyles.contains(style)) return this;
    return copyWith(
        likedStyles: [...likedStyles, style], updatedAt: DateTime.now());
  }

  /// Удалить понравившийся стиль
  UserPreferences removeLikedStyle(String style) => copyWith(
        likedStyles: likedStyles.where((s) => s != style).toList(),
        updatedAt: DateTime.now(),
      );

  /// Добавить не понравившийся стиль
  UserPreferences addDislikedStyle(String style) {
    if (dislikedStyles.contains(style)) return this;
    return copyWith(
        dislikedStyles: [...dislikedStyles, style], updatedAt: DateTime.now());
  }

  /// Добавить город в предпочтения
  UserPreferences addPreferredCity(String city) {
    if (preferredCities.contains(city)) return this;
    return copyWith(
        preferredCities: [...preferredCities, city], updatedAt: DateTime.now());
  }

  /// Добавить запрос в историю
  UserPreferences addSearchRequest(String request) {
    final newHistory = [
      {'query': request, 'timestamp': DateTime.now().toIso8601String()},
      ...searchHistory,
    ];

    // Ограничиваем историю 50 записями
    if (newHistory.length > 50) {
      newHistory.removeRange(50, newHistory.length);
    }

    return copyWith(searchHistory: newHistory, updatedAt: DateTime.now());
  }

  /// Добавить взаимодействие
  UserPreferences addInteraction({
    required String specialistId,
    required String action, // 'view', 'like', 'contact', 'book'
    Map<String, dynamic>? metadata,
  }) {
    final newInteraction = {
      'specialistId': specialistId,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };

    final newHistory = [newInteraction, ...interactionHistory];

    // Ограничиваем историю 100 записями
    if (newHistory.length > 100) {
      newHistory.removeRange(100, newHistory.length);
    }

    return copyWith(interactionHistory: newHistory, updatedAt: DateTime.now());
  }

  /// Обновить предпочитаемый бюджет
  UserPreferences updatePreferredBudget(double budget) =>
      copyWith(preferredBudget: budget, updatedAt: DateTime.now());

  /// Получить предпочтения для алгоритма совместимости
  Map<String, dynamic> getCompatibilityPreferences() => {
        'preferredStyles': likedStyles,
        'preferredBudget': preferredBudget,
        'preferredCities': preferredCities,
        'dislikedStyles': dislikedStyles,
        'preferredEventTypes': preferredEventTypes,
        'budgetRange': budgetRange,
        'stylePreferences': stylePreferences,
        'experiencePreferences': experiencePreferences,
        'ratingPreferences': ratingPreferences,
      };

  /// Получить последние поисковые запросы
  List<String> getRecentSearchQueries({int limit = 5}) =>
      searchHistory.take(limit).map((item) => item['query'] as String).toList();

  /// Получить популярные категории из истории
  List<String> getPopularCategories({int limit = 5}) {
    final categoryCounts = <String, int>{};

    for (final interaction in interactionHistory) {
      final category = interaction['category'] as String?;
      if (category != null) {
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }

    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(limit).map((entry) => entry.key).toList();
  }

  /// Получить предпочитаемый диапазон цен
  Map<String, double> getPreferredPriceRange() {
    if (budgetRange.isNotEmpty) {
      return {
        'min': (budgetRange['min'] as num?)?.toDouble() ?? 0.0,
        'max': (budgetRange['max'] as num?)?.toDouble() ?? 100000.0,
      };
    }

    // Вычисляем на основе предпочитаемого бюджета
    final budget = preferredBudget;
    if (budget > 0) {
      return {'min': budget * 0.7, 'max': budget * 1.3};
    }

    return {'min': 0.0, 'max': 100000.0};
  }

  /// Проверить, есть ли предпочтения
  bool get hasPreferences =>
      likedStyles.isNotEmpty ||
      preferredBudget > 0 ||
      preferredCities.isNotEmpty ||
      pastRequests.isNotEmpty ||
      favoriteCategories.isNotEmpty;

  /// Получить количество взаимодействий
  int get interactionCount => interactionHistory.length;

  /// Получить количество поисковых запросов
  int get searchCount => searchHistory.length;
}
