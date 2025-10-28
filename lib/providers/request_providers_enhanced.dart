import 'package:event_marketplace_app/models/request_enhanced.dart';
import 'package:event_marketplace_app/services/request_service_enhanced.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для получения заявок
final requestsProvider =
    FutureProvider.family<List<RequestEnhanced>, RequestFilters?>(
  (ref, filters) async {
    return RequestServiceEnhanced.getRequests(filters: filters);
  },
);

/// Провайдер для получения заявки по ID
final requestByIdProvider = FutureProvider.family<RequestEnhanced?, String>(
  (ref, requestId) async {
    return RequestServiceEnhanced.getRequestById(requestId);
  },
);

/// Провайдер для получения заявок пользователя
final userRequestsProvider = FutureProvider<List<RequestEnhanced>>(
  (ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    return RequestServiceEnhanced.getUserRequests(user.uid);
  },
);

/// Провайдер для получения ближайших заявок
final nearbyRequestsProvider =
    FutureProvider.family<List<RequestEnhanced>, Map<String, dynamic>>(
  (ref, params) async {
    final latitude = params['latitude'] as double;
    final longitude = params['longitude'] as double;
    final radiusKm = params['radiusKm'] as double;
    final filters = params['filters'] as RequestFilters?;

    return RequestServiceEnhanced.getNearbyRequests(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      filters: filters,
    );
  },
);

/// Провайдер для фильтров заявок
final requestFiltersProvider =
    StateNotifierProvider<RequestFiltersNotifier, RequestFilters>(
  (ref) => RequestFiltersNotifier(),
);

/// Провайдер для сортировки заявок
final requestSortProvider = StateProvider<String>((ref) => 'date');

/// Провайдер для поиска заявок
final requestSearchProvider = StateProvider<String>((ref) => '');

/// Провайдер для категорий заявок
final requestCategoriesProvider = FutureProvider<List<String>>(
  (ref) async {
    // Здесь можно получить категории из Firestore или статический список
    return [
      'Фотография',
      'Кейтеринг',
      'Музыка',
      'Декор',
      'Ведущий',
      'Видеосъемка',
      'Анимация',
      'Транспорт',
      'Безопасность',
      'Другое',
    ];
  },
);

/// Провайдер для подкатегорий заявок
final requestSubcategoriesProvider =
    FutureProvider.family<List<String>, String>(
  (ref, category) async {
    final subcategoriesMap = {
      'Фотография': [
        'Свадебная',
        'Портретная',
        'Студийная',
        'Уличная',
        'Событийная',
      ],
      'Кейтеринг': [
        'Банкет',
        'Фуршет',
        'Кофе-брейк',
        'Детский',
        'Корпоративный',
      ],
      'Музыка': ['Живая музыка', 'DJ', 'Вокал', 'Инструментальная', 'Караоке'],
      'Декор': ['Цветы', 'Шары', 'Свет', 'Ткани', 'Мебель'],
      'Ведущий': [
        'Свадьба',
        'Корпоратив',
        'День рождения',
        'Детский праздник',
        'Конференция',
      ],
      'Видеосъемка': [
        'Свадебная',
        'Корпоративная',
        'Реклама',
        'Документальная',
        'Событийная',
      ],
      'Анимация': [
        'Детская',
        'Взрослая',
        'Корпоративная',
        'Свадебная',
        'Тематическая',
      ],
      'Транспорт': [
        'Автомобиль',
        'Микроавтобус',
        'Автобус',
        'Лимузин',
        'Мотоцикл',
      ],
      'Безопасность': [
        'Охрана',
        'Контроль доступа',
        'Видеонаблюдение',
        'Пожарная безопасность',
      ],
      'Другое': ['Услуги', 'Консультации', 'Обучение', 'Ремонт', 'Доставка'],
    };

    return subcategoriesMap[category] ?? [];
  },
);

/// Провайдер для приоритетов заявок
final requestPrioritiesProvider = Provider<List<RequestPriority>>(
  (ref) => RequestPriority.values,
);

/// Провайдер для статусов заявок
final requestStatusesProvider = Provider<List<RequestStatus>>(
  (ref) => RequestStatus.values,
);

/// Провайдер для языков
final requestLanguagesProvider = Provider<List<String>>(
  (ref) => ['ru', 'en', 'de', 'fr', 'es', 'it'],
);

/// Провайдер для навыков
final requestSkillsProvider = FutureProvider<List<String>>(
  (ref) async {
    return [
      'Фотография',
      'Видеосъемка',
      'Обработка фото',
      'Монтаж видео',
      'Кулинария',
      'Сервировка',
      'Игра на инструментах',
      'Вокал',
      'DJ',
      'Дизайн',
      'Декорирование',
      'Цветы',
      'Ведущий',
      'Анимация',
      'Танцы',
      'Актерское мастерство',
      'Организация мероприятий',
      'Звук',
      'Свет',
      'Транспорт',
      'Безопасность',
      'Администратор',
      'Менеджер',
      'Консультант',
      'Тренер',
    ];
  },
);

/// Провайдер для тегов
final requestTagsProvider = FutureProvider<List<String>>(
  (ref) async {
    return [
      'свадьба',
      'корпоратив',
      'день рождения',
      'детский праздник',
      'конференция',
      'выставка',
      'концерт',
      'фестиваль',
      'спорт',
      'образование',
      'здоровье',
      'красота',
      'мода',
      'технологии',
      'бизнес',
      'творчество',
      'путешествия',
      'еда',
      'музыка',
      'танцы',
      'искусство',
      'культура',
      'развлечения',
      'отдых',
      'спорт',
    ];
  },
);

/// Провайдер для аналитики заявок
final requestAnalyticsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    // Здесь можно получить аналитику из Firestore
    return {
      'totalRequests': 0,
      'activeRequests': 0,
      'completedRequests': 0,
      'cancelledRequests': 0,
      'averageBudget': 0.0,
      'popularCategories': [],
      'topCities': [],
      'successRate': 0.0,
    };
  },
);

/// Провайдер для статистики пользователя
final userRequestStatsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final userRequests = await RequestServiceEnhanced.getUserRequests(user.uid);

    return {
      'totalRequests': userRequests.length,
      'activeRequests':
          userRequests.where((r) => r.status == RequestStatus.open).length,
      'completedRequests':
          userRequests.where((r) => r.status == RequestStatus.completed).length,
      'cancelledRequests':
          userRequests.where((r) => r.status == RequestStatus.cancelled).length,
      'totalBudget': userRequests.fold(0, (sum, r) => sum + r.budget),
      'averageBudget': userRequests.isNotEmpty
          ? userRequests.fold(0, (sum, r) => sum + r.budget) /
              userRequests.length
          : 0.0,
      'categories': userRequests.map((r) => r.category).toSet().toList(),
      'cities': userRequests.map((r) => r.city).toSet().toList(),
    };
  },
);

/// Провайдер для уведомлений о заявках
final requestNotificationsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    yield* FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('data.type', isEqualTo: 'request')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                },)
            .toList(),);
  },
);

/// Провайдер для непрочитанных уведомлений
final unreadNotificationsCountProvider = StreamProvider<int>(
  (ref) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    yield* FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  },
);

/// Провайдер для управления фильтрами заявок
class RequestFiltersNotifier extends StateNotifier<RequestFilters> {
  RequestFiltersNotifier() : super(const RequestFilters());

  void updateCategory(String? category) {
    state = RequestFilters(
      category: category,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateSubcategory(String? subcategory) {
    state = RequestFilters(
      category: state.category,
      subcategory: subcategory,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateCity(String? city) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateBudget(double? minBudget, double? maxBudget) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: state.city,
      minBudget: minBudget,
      maxBudget: maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: startDate,
      endDate: endDate,
      status: state.status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateStatus(RequestStatus? status) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updatePriority(RequestPriority? priority) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateRemote(bool? isRemote) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: state.priority,
      isRemote: isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateLanguage(String? language) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateTags(List<String>? tags) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateRequiredSkills(List<String>? requiredSkills) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: requiredSkills,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateSearchQuery(String? searchQuery) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
      radius: state.radius,
    );
  }

  void updateLocation(double? latitude, double? longitude, double? radius) {
    state = RequestFilters(
      category: state.category,
      subcategory: state.subcategory,
      city: state.city,
      minBudget: state.minBudget,
      maxBudget: state.maxBudget,
      startDate: state.startDate,
      endDate: state.endDate,
      status: state.status,
      priority: state.priority,
      isRemote: state.isRemote,
      language: state.language,
      tags: state.tags,
      requiredSkills: state.requiredSkills,
      searchQuery: state.searchQuery,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  void clearFilters() {
    state = const RequestFilters();
  }

  void resetFilters() {
    state = const RequestFilters();
  }
}
