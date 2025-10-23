import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'category_service.dart';
import 'post_service.dart';
import 'tariff_service.dart';
import 'test_data_service.dart';

/// Service for testing Firestore configuration
class FirestoreTestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final CategoryService _categoryService = CategoryService();
  final PostService _postService = PostService();
  final TariffService _tariffService = TariffService();
  final TestDataService _testDataService = TestDataService();

  /// Test Firestore permissions for authenticated users
  Future<bool> testAuthenticatedUserPermissions() async {
    try {
      debugPrint(
          '🔐 Тестирование прав доступа для авторизованных пользователей...');

      // Test reading posts (feed)
      final posts = await _postService.getPosts(limit: 5);
      debugPrint('✅ Чтение ленты: ${posts.length} постов загружено');

      // Test reading categories
      final categories = await _categoryService.getIdeaCategories();
      debugPrint(
          '✅ Чтение категорий: ${categories.length} категорий загружено');

      // Test reading specialists
      final specialists = await _testDataService.getTestSpecialists();
      debugPrint(
          '✅ Чтение специалистов: ${specialists.length} специалистов загружено');

      // Test reading tariffs
      final tariffs = await _tariffService.getTariffs();
      debugPrint('✅ Чтение тарифов: ${tariffs.length} тарифов загружено');

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка тестирования прав авторизованного пользователя: $e');
      return false;
    }
  }

  /// Test Firestore permissions for unauthenticated users
  Future<bool> testUnauthenticatedUserPermissions() async {
    try {
      debugPrint(
          '🔓 Тестирование прав доступа для неавторизованных пользователей...');

      // Sign out first
      await _authService.signOut();

      // Test reading posts (should work for unauthenticated users)
      final posts = await _postService.getPosts(limit: 5);
      debugPrint(
          '✅ Чтение ленты (неавторизованный): ${posts.length} постов загружено');

      // Test reading categories (should work for unauthenticated users)
      final categories = await _categoryService.getIdeaCategories();
      debugPrint(
          '✅ Чтение категорий (неавторизованный): ${categories.length} категорий загружено');

      // Test reading specialists (should work for unauthenticated users)
      final specialists = await _testDataService.getTestSpecialists();
      debugPrint(
          '✅ Чтение специалистов (неавторизованный): ${specialists.length} специалистов загружено');

      // Test reading tariffs (should work for unauthenticated users)
      final tariffs = await _tariffService.getTariffs();
      debugPrint(
          '✅ Чтение тарифов (неавторизованный): ${tariffs.length} тарифов загружено');

      return true;
    } catch (e) {
      debugPrint(
          '❌ Ошибка тестирования прав неавторизованного пользователя: $e');
      return false;
    }
  }

  /// Test creating posts (authenticated users only)
  Future<bool> testPostCreation() async {
    try {
      debugPrint('📝 Тестирование создания постов...');

      // Test creating a post
      final postId = await _postService.createPost(
        authorId: 'test_user_id',
        text: 'Тестовый пост для проверки прав доступа',
        tags: ['тест', 'проверка'],
        authorName: 'Тестовый пользователь',
        authorAvatarUrl: 'https://picsum.photos/200?random=999',
      );

      if (postId != null) {
        debugPrint('✅ Создание поста: успешно (ID: $postId)');
        return true;
      } else {
        debugPrint('❌ Создание поста: не удалось');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Ошибка тестирования создания постов: $e');
      return false;
    }
  }

  /// Test chat permissions (authenticated users only)
  Future<bool> testChatPermissions() async {
    try {
      debugPrint('💬 Тестирование прав доступа к чатам...');

      // Test reading chats
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('members', arrayContains: 'test_user_id')
          .get();

      debugPrint('✅ Чтение чатов: ${chatsSnapshot.docs.length} чатов найдено');

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка тестирования прав доступа к чатам: $e');
      return false;
    }
  }

  /// Test user profile permissions
  Future<bool> testUserProfilePermissions() async {
    try {
      debugPrint('👤 Тестирование прав доступа к профилю пользователя...');

      // Test reading user profile
      final userDoc =
          await _firestore.collection('users').doc('test_user_id').get();

      if (userDoc.exists) {
        debugPrint('✅ Чтение профиля пользователя: успешно');
        return true;
      } else {
        debugPrint(
            '⚠️ Профиль пользователя не найден (это нормально для тестов)');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Ошибка тестирования прав доступа к профилю: $e');
      return false;
    }
  }

  /// Run comprehensive Firestore test
  Future<Map<String, bool>> runComprehensiveTest() async {
    debugPrint('🚀 Запуск комплексного тестирования Firestore...');

    final results = <String, bool>{};

    // Test unauthenticated permissions
    results['unauthenticated_read'] =
        await testUnauthenticatedUserPermissions();

    // Test authenticated permissions
    results['authenticated_read'] = await testAuthenticatedUserPermissions();

    // Test post creation
    results['post_creation'] = await testPostCreation();

    // Test chat permissions
    results['chat_permissions'] = await testChatPermissions();

    // Test user profile permissions
    results['user_profile'] = await testUserProfilePermissions();

    // Print summary
    debugPrint('\n📊 Результаты тестирования:');
    results.forEach((test, result) {
      debugPrint(
          '${result ? '✅' : '❌'} $test: ${result ? 'ПРОЙДЕН' : 'ПРОВАЛЕН'}');
    });

    final passedTests = results.values.where((result) => result).length;
    final totalTests = results.length;
    debugPrint('\n🎯 Итого: $passedTests из $totalTests тестов пройдено');

    return results;
  }

  /// Initialize test data and run tests
  Future<void> initializeAndTest() async {
    try {
      debugPrint('🔧 Инициализация тестовых данных...');

      // Create test data
      await _testDataService.createAllTestData();

      debugPrint('⏳ Ожидание 3 секунды для синхронизации данных...');
      await Future.delayed(const Duration(seconds: 3));

      // Run comprehensive test
      await runComprehensiveTest();
    } catch (e) {
      debugPrint('❌ Ошибка инициализации и тестирования: $e');
    }
  }
}
