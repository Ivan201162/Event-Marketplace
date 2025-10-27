import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/idea_enhanced.dart';
import '../services/idea_service_enhanced.dart';

/// Провайдер для получения идей
final ideasProvider = FutureProvider.family<List<IdeaEnhanced>, IdeaFilters?>(
  (ref, filters) async {
    return await IdeaServiceEnhanced.getIdeas(filters: filters);
  },
);

/// Провайдер для получения идеи по ID
final ideaByIdProvider = FutureProvider.family<IdeaEnhanced?, String>(
  (ref, ideaId) async {
    return await IdeaServiceEnhanced.getIdeaById(ideaId);
  },
);

/// Провайдер для получения идей пользователя
final userIdeasProvider = FutureProvider.family<List<IdeaEnhanced>, String>(
  (ref, userId) async {
    return await IdeaServiceEnhanced.getUserIdeas(userId);
  },
);

/// Провайдер для получения трендовых идей
final trendingIdeasProvider =
    FutureProvider.family<List<IdeaEnhanced>, String?>(
  (ref, category) async {
    return await IdeaServiceEnhanced.getTrendingIdeas(category: category);
  },
);

/// Провайдер для получения рекомендуемых идей
final recommendedIdeasProvider = FutureProvider<List<IdeaEnhanced>>(
  (ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    return await IdeaServiceEnhanced.getRecommendedIdeas(userId: user.uid);
  },
);

/// Провайдер для поиска идей
final searchIdeasProvider =
    FutureProvider.family<List<IdeaEnhanced>, Map<String, dynamic>>(
  (ref, params) async {
    final query = params['query'] as String;
    final filters = params['filters'] as IdeaFilters?;
    final limit = params['limit'] as int? ?? 20;

    return await IdeaServiceEnhanced.searchIdeas(
      query: query,
      filters: filters,
      limit: limit,
    );
  },
);

/// Провайдер для фильтров идей
final ideaFiltersProvider =
    StateNotifierProvider<IdeaFiltersNotifier, IdeaFilters>(
  (ref) => IdeaFiltersNotifier(),
);

/// Провайдер для сортировки идей
final ideaSortProvider = StateProvider<String>((ref) => 'createdAt');

/// Провайдер для поиска идей
final ideaSearchProvider = StateProvider<String>((ref) => '');

/// Провайдер для типов идей
final ideaTypesProvider = Provider<List<IdeaType>>(
  (ref) => IdeaType.values,
);

/// Провайдер для статусов идей
final ideaStatusesProvider = Provider<List<IdeaStatus>>(
  (ref) => IdeaStatus.values,
);

/// Провайдер для приватности идей
final ideaPrivacyProvider = Provider<List<IdeaPrivacy>>(
  (ref) => IdeaPrivacy.values,
);

/// Провайдер для категорий идей
final ideaCategoriesProvider = FutureProvider<List<String>>(
  (ref) async {
    return [
      'Фотография',
      'Музыка',
      'Кулинария',
      'Путешествия',
      'Технологии',
      'Спорт',
      'Искусство',
      'Мода',
      'Красота',
      'Здоровье',
      'Образование',
      'Бизнес',
      'Развлечения',
      'Семья',
      'Другое',
    ];
  },
);

/// Провайдер для тегов идей
final ideaTagsProvider = FutureProvider<List<String>>(
  (ref) async {
    return [
      'творчество',
      'вдохновение',
      'идея',
      'проект',
      'инновации',
      'дизайн',
      'стиль',
      'красота',
      'здоровье',
      'спорт',
      'путешествия',
      'еда',
      'музыка',
      'искусство',
      'технологии',
      'бизнес',
      'образование',
      'семья',
      'друзья',
      'любовь',
      'счастье',
      'успех',
      'мотивация',
      'развитие',
      'обучение',
    ];
  },
);

/// Провайдер для аналитики идей
final ideaAnalyticsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final userIdeas = await IdeaServiceEnhanced.getUserIdeas(user.uid);

    return {
      'totalIdeas': userIdeas.length,
      'publishedIdeas':
          userIdeas.where((i) => i.status == IdeaStatus.published).length,
      'draftIdeas': userIdeas.where((i) => i.status == IdeaStatus.draft).length,
      'featuredIdeas': userIdeas.where((i) => i.isFeatured).length,
      'trendingIdeas': userIdeas.where((i) => i.isTrending).length,
      'totalViews': userIdeas.fold(0, (sum, i) => sum + i.views),
      'totalLikes': userIdeas.fold(0, (sum, i) => sum + i.likes),
      'totalComments': userIdeas.fold(0, (sum, i) => sum + i.comments),
      'totalShares': userIdeas.fold(0, (sum, i) => sum + i.shares),
      'totalBookmarks': userIdeas.fold(0, (sum, i) => sum + i.bookmarks),
      'averageRating': userIdeas.isNotEmpty
          ? userIdeas.fold(0.0, (sum, i) => sum + i.rating) / userIdeas.length
          : 0.0,
      'categories':
          userIdeas.map((i) => i.categories).expand((x) => x).toSet().toList(),
      'tags': userIdeas.map((i) => i.tags).expand((x) => x).toSet().toList(),
    };
  },
);

/// Провайдер для статистики идей
final ideaStatsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    // Здесь можно получить общую статистику по идеям
    return {
      'totalIdeas': 0,
      'publishedIdeas': 0,
      'draftIdeas': 0,
      'featuredIdeas': 0,
      'trendingIdeas': 0,
      'totalViews': 0,
      'totalLikes': 0,
      'totalComments': 0,
      'totalShares': 0,
      'totalBookmarks': 0,
      'averageRating': 0.0,
      'popularCategories': [],
      'trendingTags': [],
      'topAuthors': [],
    };
  },
);

/// Провайдер для уведомлений об идеях
final ideaNotificationsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    yield* FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('data.type', whereIn: [
          'idea_mention',
          'idea_like',
          'idea_comment',
          'idea_repost'
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  },
);

/// Провайдер для непрочитанных уведомлений об идеях
final unreadIdeaNotificationsCountProvider = StreamProvider<int>(
  (ref) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    yield* FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('data.type', whereIn: [
          'idea_mention',
          'idea_like',
          'idea_comment',
          'idea_repost'
        ])
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  },
);

/// Провайдер для управления фильтрами идей
class IdeaFiltersNotifier extends StateNotifier<IdeaFilters> {
  IdeaFiltersNotifier() : super(const IdeaFilters());

  void updateType(IdeaType? type) {
    state = IdeaFilters(
      type: type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateStatus(IdeaStatus? status) {
    state = IdeaFilters(
      type: state.type,
      status: status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updatePrivacy(IdeaPrivacy? privacy) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateAuthorId(String? authorId) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateCategories(List<String>? categories) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateTags(List<String>? tags) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateSearchQuery(String? searchQuery) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: startDate,
      endDate: endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateRatingRange(double? minRating, double? maxRating) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: minRating,
      maxRating: maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateVerified(bool? isVerified) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateFeatured(bool? isFeatured) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateTrending(bool? isTrending) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: isTrending,
      language: state.language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateLanguage(String? language) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: language,
      location: state.location,
      radius: state.radius,
    );
  }

  void updateLocation(Map<String, dynamic>? location, double? radius) {
    state = IdeaFilters(
      type: state.type,
      status: state.status,
      privacy: state.privacy,
      authorId: state.authorId,
      categories: state.categories,
      tags: state.tags,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
      minRating: state.minRating,
      maxRating: state.maxRating,
      isVerified: state.isVerified,
      isFeatured: state.isFeatured,
      isTrending: state.isTrending,
      language: state.language,
      location: location,
      radius: radius,
    );
  }

  void clearFilters() {
    state = const IdeaFilters();
  }
}
