import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tool/seed_local_data.dart';

/// Провайдер для статуса инициализации локальных данных
final localDataInitializedProvider = FutureProvider<bool>((ref) async {
  await LocalDataSeeder.seedData();
  return true;
});

/// Провайдер для получения локальных данных пользователя
final localUserDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final data = await LocalDataSeeder.loadLocalData();
  return data?['currentUser'] as Map<String, dynamic>?;
});

/// Провайдер для получения списка локальных специалистов
final localSpecialistsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await LocalDataSeeder.loadLocalData();
  return (data?['specialists'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
});

/// Провайдер для получения списка локальных постов ленты
final localFeedPostsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await LocalDataSeeder.loadLocalData();
  return (data?['feedPosts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
});

/// Провайдер для получения списка локальных заявок
final localRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await LocalDataSeeder.loadLocalData();
  return (data?['requests'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
});

/// Провайдер для получения списка локальных чатов
final localChatsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await LocalDataSeeder.loadLocalData();
  return (data?['chats'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
});

/// Провайдер для получения списка локальных идей
final localIdeasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await LocalDataSeeder.loadLocalData();
  return (data?['ideas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
});

/// Провайдер для получения списка локальных категорий
final localCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await LocalDataSeeder.loadLocalData();
  return (data?['categories'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
});