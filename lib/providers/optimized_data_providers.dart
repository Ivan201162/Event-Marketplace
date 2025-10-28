import 'package:event_marketplace_app/models/category.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/services/optimized_applications_service.dart';
import 'package:event_marketplace_app/services/optimized_chat_service.dart';
import 'package:event_marketplace_app/services/optimized_data_service.dart';
import 'package:event_marketplace_app/services/optimized_feed_service.dart';
import 'package:event_marketplace_app/services/optimized_ideas_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Сервисы
final optimizedDataServiceProvider = Provider<OptimizedDataService>((ref) {
  return OptimizedDataService();
});

final optimizedFeedServiceProvider = Provider<OptimizedFeedService>((ref) {
  return OptimizedFeedService();
});

final optimizedChatServiceProvider = Provider<OptimizedChatService>((ref) {
  return OptimizedChatService();
});

final optimizedIdeasServiceProvider = Provider<OptimizedIdeasService>((ref) {
  return OptimizedIdeasService();
});

final optimizedApplicationsServiceProvider =
    Provider<OptimizedApplicationsService>((ref) {
  return OptimizedApplicationsService();
});

// Провайдеры для категорий
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.read(optimizedDataServiceProvider);
  return await service.getCategories();
});

final categoryStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.read(optimizedDataServiceProvider);
  return service.getCategoryStats();
});

// Провайдеры для специалистов
final popularSpecialistsProvider =
    FutureProvider.family<List<Specialist>, Map<String, dynamic>>(
        (ref, params) async {
  final service = ref.read(optimizedDataServiceProvider);
  return service.getPopularSpecialists(
    city: params['city'],
    category: params['category'],
    limit: params['limit'] ?? 10,
  );
});

final specialistsByCityProvider =
    FutureProvider.family<List<Specialist>, Map<String, dynamic>>(
        (ref, params) async {
  final service = ref.read(optimizedDataServiceProvider);
  return service.getSpecialistsByCity(
    city: params['city'] as String,
    category: params['category'] as String?,
    sortBy: params['sortBy'] as String? ?? 'popularity',
    limit: params['limit'] as int? ?? 20,
  );
});

// Провайдеры для ленты
final feedProvider =
    FutureProvider.family<FeedState, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(optimizedFeedServiceProvider);
  return service.getPosts(
    limit: params['limit'] as int? ?? 20,
    lastDocument: params['lastDocument'],
    forceRefresh: params['forceRefresh'] as bool? ?? false,
  );
});

final userPostsProvider =
    FutureProvider.family<List<EnhancedFeedPost>, String>((ref, userId) async {
  final service = ref.read(optimizedFeedServiceProvider);
  return service.getUserPosts(userId);
});

// Провайдеры для чатов
final userChatsProvider =
    StreamProvider.family<List<EnhancedChat>, String>((ref, userId) {
  final service = ref.read(optimizedChatServiceProvider);
  return service.getUserChatsStream(userId);
});

final chatMessagesProvider =
    StreamProvider.family<List<EnhancedMessage>, String>((ref, chatId) {
  final service = ref.read(optimizedChatServiceProvider);
  return service.getChatMessagesStream(chatId);
});

final unreadMessagesCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.read(optimizedChatServiceProvider);
  return service.getUnreadMessagesCount(userId);
});

// Провайдеры для идей
final ideasProvider = FutureProvider.family<IdeasState, Map<String, dynamic>>(
    (ref, params) async {
  final service = ref.read(optimizedIdeasServiceProvider);
  return service.getIdeas(
    limit: params['limit'] as int? ?? 20,
    lastDocument: params['lastDocument'],
    category: params['category'] as String?,
    forceRefresh: params['forceRefresh'] as bool? ?? false,
  );
});

final userIdeasProvider =
    FutureProvider.family<List<Idea>, String>((ref, userId) async {
  final service = ref.read(optimizedIdeasServiceProvider);
  return service.getUserIdeas(userId);
});

final savedIdeasProvider =
    FutureProvider.family<List<Idea>, String>((ref, userId) async {
  final service = ref.read(optimizedIdeasServiceProvider);
  return service.getSavedIdeas(userId);
});

final popularIdeasProvider = FutureProvider<List<Idea>>((ref) async {
  final service = ref.read(optimizedIdeasServiceProvider);
  return service.getPopularIdeas();
});

// Провайдеры для заявок
final userBookingsProvider =
    StreamProvider.family<List<Booking>, Map<String, dynamic>>((ref, params) {
  final service = ref.read(optimizedApplicationsServiceProvider);
  return service.getUserBookingsStream(
    params['userId'] as String,
    isSpecialist: params['isSpecialist'] as bool? ?? false,
  );
});

final bookingStatsProvider =
    FutureProvider.family<Map<String, int>, Map<String, dynamic>>(
        (ref, params) async {
  final service = ref.read(optimizedApplicationsServiceProvider);
  return service.getBookingStats(
    params['userId'] as String,
    isSpecialist: params['isSpecialist'] as bool? ?? false,
  );
});

final bookingsByStatusProvider =
    FutureProvider.family<List<Booking>, Map<String, dynamic>>(
        (ref, params) async {
  final service = ref.read(optimizedApplicationsServiceProvider);
  return service.getBookingsByStatus(
    params['userId'] as String,
    params['status'] as BookingStatus,
    isSpecialist: params['isSpecialist'] as bool? ?? false,
  );
});

// Провайдеры для обновления данных
final refreshDataProvider =
    Provider.family<void Function(), String>((ref, dataType) {
  return () {
    switch (dataType) {
      case 'categories':
        ref.invalidate(categoriesProvider);
      case 'specialists':
        ref.invalidate(popularSpecialistsProvider);
        ref.invalidate(specialistsByCityProvider);
      case 'feed':
        ref.invalidate(feedProvider);
      case 'chats':
        ref.invalidate(userChatsProvider);
      case 'ideas':
        ref.invalidate(ideasProvider);
      case 'bookings':
        ref.invalidate(userBookingsProvider);
    }
  };
});

// Провайдер для очистки кэша
final clearCacheProvider = Provider<void Function()>((ref) {
  return () {
    final dataService = ref.read(optimizedDataServiceProvider);
    final feedService = ref.read(optimizedFeedServiceProvider);
    final chatService = ref.read(optimizedChatServiceProvider);
    final ideasService = ref.read(optimizedIdeasServiceProvider);
    final applicationsService = ref.read(optimizedApplicationsServiceProvider);

    dataService.clearCache();
    feedService.clearCache();
    chatService.clearCache();
    ideasService.clearCache();
    applicationsService.clearCache();

    // Инвалидируем все провайдеры
    ref.invalidate(categoriesProvider);
    ref.invalidate(popularSpecialistsProvider);
    ref.invalidate(specialistsByCityProvider);
    ref.invalidate(feedProvider);
    ref.invalidate(userChatsProvider);
    ref.invalidate(ideasProvider);
    ref.invalidate(userBookingsProvider);
  };
});
