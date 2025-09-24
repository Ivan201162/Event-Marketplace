import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/optimized_firestore_service.dart';

/// Провайдер для получения специалистов с оптимизацией
final specialistsProvider = StreamProvider<QuerySnapshot>((ref) {
  return OptimizedFirestoreService.getCollectionStream(
    'specialists',
    limit: 20,
    orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
  );
});

/// Провайдер для получения событий с оптимизацией
final eventsProvider = StreamProvider<QuerySnapshot>((ref) {
  return OptimizedFirestoreService.getCollectionStream(
    'events',
    limit: 20,
    orderBy: [const QueryOrder(field: 'date', descending: false)],
  );
});

/// Провайдер для получения чатов с оптимизацией
final chatsProvider = StreamProvider<QuerySnapshot>((ref) {
  return OptimizedFirestoreService.getCollectionStream(
    'chats',
    limit: 50,
    orderBy: [const QueryOrder(field: 'lastMessageTime', descending: true)],
  );
});

/// Провайдер для получения идей с оптимизацией
final ideasProvider = StreamProvider<QuerySnapshot>((ref) {
  return OptimizedFirestoreService.getCollectionStream(
    'ideas',
    limit: 20,
    orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
  );
});

/// Провайдер для получения бронирований с оптимизацией
final bookingsProvider = StreamProvider<QuerySnapshot>((ref) {
  return OptimizedFirestoreService.getCollectionStream(
    'bookings',
    limit: 50,
    orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
  );
});

/// Провайдер для получения отзывов с оптимизацией
final reviewsProvider = StreamProvider<QuerySnapshot>((ref) {
  return OptimizedFirestoreService.getCollectionStream(
    'reviews',
    limit: 20,
    orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
  );
});

/// Провайдер для получения уведомлений с оптимизацией
final notificationsProvider = StreamProvider<QuerySnapshot>((ref) {
  return OptimizedFirestoreService.getCollectionStream(
    'notifications',
    limit: 50,
    orderBy: [const QueryOrder(field: 'createdAt', descending: true)],
  );
});

/// Провайдер для получения сообщений чата с оптимизацией
final chatMessagesProvider =
    StreamProvider.family<QuerySnapshot, String>((ref, chatId) {
  return OptimizedFirestoreService.getCollectionStream(
    'chats/$chatId/messages',
    limit: 50,
    orderBy: [const QueryOrder(field: 'timestamp', descending: true)],
  );
});

/// Провайдер для получения профиля пользователя с оптимизацией
final userProfileProvider =
    StreamProvider.family<DocumentSnapshot?, String>((ref, userId) {
  return Stream.fromFuture(
    OptimizedFirestoreService.getDocument('users', userId),
  );
});

/// Провайдер для получения профиля специалиста с оптимизацией
final specialistProfileProvider =
    StreamProvider.family<DocumentSnapshot?, String>((ref, specialistId) {
  return Stream.fromFuture(
    OptimizedFirestoreService.getDocument('specialists', specialistId),
  );
});

/// Провайдер для получения деталей события с оптимизацией
final eventDetailsProvider =
    StreamProvider.family<DocumentSnapshot?, String>((ref, eventId) {
  return Stream.fromFuture(
    OptimizedFirestoreService.getDocument('events', eventId),
  );
});

/// Провайдер для получения деталей идеи с оптимизацией
final ideaDetailsProvider =
    StreamProvider.family<DocumentSnapshot?, String>((ref, ideaId) {
  return Stream.fromFuture(
    OptimizedFirestoreService.getDocument('ideas', ideaId),
  );
});

/// Провайдер для получения деталей бронирования с оптимизацией
final bookingDetailsProvider =
    StreamProvider.family<DocumentSnapshot?, String>((ref, bookingId) {
  return Stream.fromFuture(
    OptimizedFirestoreService.getDocument('bookings', bookingId),
  );
});

/// Провайдер для поиска специалистов с оптимизацией
final searchSpecialistsProvider =
    StreamProvider.family<QuerySnapshot, String>((ref, query) {
  if (query.isEmpty) {
    return const Stream.empty();
  }

  return OptimizedFirestoreService.getCollectionStream(
    'specialists',
    limit: 20,
    where: [
      QueryFilter(field: 'name', value: query),
    ],
    orderBy: [const QueryOrder(field: 'rating', descending: true)],
  );
});

/// Провайдер для поиска событий с оптимизацией
final searchEventsProvider =
    StreamProvider.family<QuerySnapshot, String>((ref, query) {
  if (query.isEmpty) {
    return const Stream.empty();
  }

  return OptimizedFirestoreService.getCollectionStream(
    'events',
    limit: 20,
    where: [
      QueryFilter(field: 'title', value: query),
    ],
    orderBy: [const QueryOrder(field: 'date', descending: false)],
  );
});

/// Провайдер для поиска идей с оптимизацией
final searchIdeasProvider =
    StreamProvider.family<QuerySnapshot, String>((ref, query) {
  if (query.isEmpty) {
    return const Stream.empty();
  }

  return OptimizedFirestoreService.getCollectionStream(
    'ideas',
    limit: 20,
    where: [
      QueryFilter(field: 'title', value: query),
    ],
    orderBy: [const QueryOrder(field: 'likes', descending: true)],
  );
});

/// Провайдер для получения статистики с оптимизацией
final statisticsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return Stream.periodic(const Duration(minutes: 5), (_) async {
    final specialists =
        await OptimizedFirestoreService.getCollection('specialists', limit: 1);
    final events =
        await OptimizedFirestoreService.getCollection('events', limit: 1);
    final ideas =
        await OptimizedFirestoreService.getCollection('ideas', limit: 1);
    final bookings =
        await OptimizedFirestoreService.getCollection('bookings', limit: 1);

    return {
      'specialistsCount': specialists.docs.length,
      'eventsCount': events.docs.length,
      'ideasCount': ideas.docs.length,
      'bookingsCount': bookings.docs.length,
      'lastUpdated': DateTime.now(),
    };
  }).asyncMap((event) => event);
});

/// Провайдер для управления кэшем Firestore
final firestoreCacheProvider = Provider<FirestoreCacheManager>((ref) {
  return FirestoreCacheManager();
});

/// Менеджер кэша Firestore
class FirestoreCacheManager {
  /// Очистка кэша
  void clearCache() {
    OptimizedFirestoreService.clearAllCache();
  }

  /// Получение статистики кэша
  Map<String, dynamic> getCacheStats() {
    return OptimizedFirestoreService.getCacheStats();
  }

  /// Очистка кэша для конкретной коллекции
  void clearCollectionCache(String collection) {
    // Реализация очистки кэша для коллекции
  }
}
