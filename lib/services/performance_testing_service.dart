import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'error_logging_service.dart';

/// Сервис для тестирования производительности
class PerformanceTestingService {
  factory PerformanceTestingService() => _instance;
  PerformanceTestingService._internal();
  static final PerformanceTestingService _instance = PerformanceTestingService._internal();

  final ErrorLoggingService _errorLogger = ErrorLoggingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Тестировать производительность ленты
  Future<Map<String, dynamic>> testFeedPerformance({
    int postsCount = 10,
    String? userId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Тест загрузки постов
      final postsStopwatch = Stopwatch()..start();
      final postsSnapshot = await _firestore
          .collection('feed')
          .limit(postsCount)
          .orderBy('createdAt', descending: true)
          .get();
      postsStopwatch.stop();

      // Тест загрузки пользователей для постов
      final usersStopwatch = Stopwatch()..start();
      final userIds = postsSnapshot.docs.map((doc) => doc.data()['authorId'] as String).toSet();

      final usersPromises = userIds.map(
        (uid) => _firestore.collection('users').doc(uid).get(),
      );
      await Future.wait(usersPromises);
      usersStopwatch.stop();

      stopwatch.stop();

      final results = {
        'operation': 'feed_performance',
        'totalTime': stopwatch.elapsedMilliseconds,
        'postsLoadTime': postsStopwatch.elapsedMilliseconds,
        'usersLoadTime': usersStopwatch.elapsedMilliseconds,
        'postsCount': postsSnapshot.docs.length,
        'usersCount': userIds.length,
        'success': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _errorLogger.logPerformance(
        operation: 'feed_performance',
        duration: stopwatch.elapsed,
        userId: userId,
        screen: 'feed',
        additionalData: results,
      );

      return results;
    } catch (e, stackTrace) {
      stopwatch.stop();

      await _errorLogger.logError(
        error: 'Feed performance test failed: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        screen: 'feed',
        action: 'performance_test',
      );

      return {
        'operation': 'feed_performance',
        'totalTime': stopwatch.elapsedMilliseconds,
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Тестировать производительность чатов
  Future<Map<String, dynamic>> testChatsPerformance({
    int chatsCount = 5,
    String? userId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Тест загрузки чатов
      final chatsStopwatch = Stopwatch()..start();
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('members', arrayContains: userId ?? 'test_user')
          .limit(chatsCount)
          .orderBy('updatedAt', descending: true)
          .get();
      chatsStopwatch.stop();

      // Тест загрузки последних сообщений
      final messagesStopwatch = Stopwatch()..start();
      final messagePromises = chatsSnapshot.docs.map(
        (chatDoc) => chatDoc.reference
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get(),
      );
      await Future.wait(messagePromises);
      messagesStopwatch.stop();

      stopwatch.stop();

      final results = {
        'operation': 'chats_performance',
        'totalTime': stopwatch.elapsedMilliseconds,
        'chatsLoadTime': chatsStopwatch.elapsedMilliseconds,
        'messagesLoadTime': messagesStopwatch.elapsedMilliseconds,
        'chatsCount': chatsSnapshot.docs.length,
        'success': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _errorLogger.logPerformance(
        operation: 'chats_performance',
        duration: stopwatch.elapsed,
        userId: userId,
        screen: 'chats',
        additionalData: results,
      );

      return results;
    } catch (e, stackTrace) {
      stopwatch.stop();

      await _errorLogger.logError(
        error: 'Chats performance test failed: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        screen: 'chats',
        action: 'performance_test',
      );

      return {
        'operation': 'chats_performance',
        'totalTime': stopwatch.elapsedMilliseconds,
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Тестировать производительность поиска
  Future<Map<String, dynamic>> testSearchPerformance({
    String searchQuery = 'фотограф',
    int resultsLimit = 20,
    String? userId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Тест поиска специалистов
      final searchStopwatch = Stopwatch()..start();
      final specialistsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'specialist')
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThan: '$searchQuery\uf8ff')
          .limit(resultsLimit)
          .get();
      searchStopwatch.stop();

      // Тест загрузки дополнительных данных
      final detailsStopwatch = Stopwatch()..start();
      final detailsPromises = specialistsSnapshot.docs.map(
        (doc) => _firestore.collection('specialist_details').doc(doc.id).get(),
      );
      await Future.wait(detailsPromises);
      detailsStopwatch.stop();

      stopwatch.stop();

      final results = {
        'operation': 'search_performance',
        'totalTime': stopwatch.elapsedMilliseconds,
        'searchTime': searchStopwatch.elapsedMilliseconds,
        'detailsLoadTime': detailsStopwatch.elapsedMilliseconds,
        'resultsCount': specialistsSnapshot.docs.length,
        'searchQuery': searchQuery,
        'success': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _errorLogger.logPerformance(
        operation: 'search_performance',
        duration: stopwatch.elapsed,
        userId: userId,
        screen: 'search',
        additionalData: results,
      );

      return results;
    } catch (e, stackTrace) {
      stopwatch.stop();

      await _errorLogger.logError(
        error: 'Search performance test failed: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        screen: 'search',
        action: 'performance_test',
      );

      return {
        'operation': 'search_performance',
        'totalTime': stopwatch.elapsedMilliseconds,
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Тестировать производительность загрузки изображений
  Future<Map<String, dynamic>> testImageLoadingPerformance({
    List<String> imageUrls = const [],
    String? userId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (imageUrls.isEmpty) {
        // Получаем тестовые URL изображений
        final postsSnapshot =
            await _firestore.collection('feed').where('imageUrl', isNull: false).limit(5).get();

        imageUrls = postsSnapshot.docs
            .map((doc) => doc.data()['imageUrl'] as String)
            .where((url) => url.isNotEmpty)
            .toList();
      }

      final results = <String, dynamic>{
        'operation': 'image_loading_performance',
        'imageUrls': imageUrls,
        'imageCount': imageUrls.length,
        'loadTimes': <int>[],
        'success': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Тестируем загрузку каждого изображения
      for (final url in imageUrls) {
        final imageStopwatch = Stopwatch()..start();

        try {
          // Имитируем загрузку изображения
          await Future.delayed(const Duration(milliseconds: 100));
          imageStopwatch.stop();

          results['loadTimes'].add(imageStopwatch.elapsedMilliseconds);
        } catch (e) {
          imageStopwatch.stop();
          results['loadTimes'].add(-1); // Ошибка загрузки
        }
      }

      stopwatch.stop();
      results['totalTime'] = stopwatch.elapsedMilliseconds;
      results['averageLoadTime'] = results['loadTimes'].isNotEmpty
          ? (results['loadTimes'] as List<int>)
                  .where((time) => time > 0)
                  .fold(0, (sum, time) => sum + time) /
              (results['loadTimes'] as List<int>).where((time) => time > 0).length
          : 0;

      await _errorLogger.logPerformance(
        operation: 'image_loading_performance',
        duration: stopwatch.elapsed,
        userId: userId,
        screen: 'images',
        additionalData: results,
      );

      return results;
    } catch (e, stackTrace) {
      stopwatch.stop();

      await _errorLogger.logError(
        error: 'Image loading performance test failed: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        screen: 'images',
        action: 'performance_test',
      );

      return {
        'operation': 'image_loading_performance',
        'totalTime': stopwatch.elapsedMilliseconds,
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Запустить полный набор тестов производительности
  Future<Map<String, dynamic>> runFullPerformanceTest({
    String? userId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('Starting full performance test...');

      final results = <String, dynamic>{
        'testSuite': 'full_performance_test',
        'startTime': DateTime.now().millisecondsSinceEpoch,
        'tests': <String, dynamic>{},
        'success': true,
      };

      // Тест ленты
      developer.log('Testing feed performance...');
      results['tests']['feed'] = await testFeedPerformance(userId: userId);

      // Тест чатов
      developer.log('Testing chats performance...');
      results['tests']['chats'] = await testChatsPerformance(userId: userId);

      // Тест поиска
      developer.log('Testing search performance...');
      results['tests']['search'] = await testSearchPerformance(userId: userId);

      // Тест загрузки изображений
      developer.log('Testing image loading performance...');
      results['tests']['images'] = await testImageLoadingPerformance(userId: userId);

      stopwatch.stop();
      results['totalTime'] = stopwatch.elapsedMilliseconds;
      results['endTime'] = DateTime.now().millisecondsSinceEpoch;

      // Проверяем, все ли тесты прошли успешно
      final allTestsSuccessful = results['tests'].values.every((test) => test['success'] == true);
      results['success'] = allTestsSuccessful;

      await _errorLogger.logInfo(
        message: 'Full performance test completed',
        userId: userId,
        screen: 'performance_test',
        action: 'full_test',
        additionalData: results,
      );

      developer.log(
        'Full performance test completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      return results;
    } catch (e, stackTrace) {
      stopwatch.stop();

      await _errorLogger.logError(
        error: 'Full performance test failed: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        screen: 'performance_test',
        action: 'full_test',
      );

      return {
        'testSuite': 'full_performance_test',
        'totalTime': stopwatch.elapsedMilliseconds,
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Получить статистику производительности
  Future<Map<String, dynamic>> getPerformanceStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('performance_logs');

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      final operationTimes = <String, List<int>>{};
      var totalOperations = 0;
      var totalTime = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final operation = data['operation'] as String?;
        final duration = data['duration'] as int?;

        if (operation != null && duration != null) {
          operationTimes.putIfAbsent(operation, () => []).add(duration);
          totalOperations++;
          totalTime += duration;
        }
      }

      final stats = <String, dynamic>{
        'totalOperations': totalOperations,
        'totalTime': totalTime,
        'averageTime': totalOperations > 0 ? totalTime / totalOperations : 0,
        'operationStats': {},
      };

      // Вычисляем статистику для каждой операции
      operationTimes.forEach((operation, times) {
        times.sort();
        stats['operationStats'][operation] = {
          'count': times.length,
          'totalTime': times.fold(0, (sum, time) => sum + time),
          'averageTime': times.fold(0, (sum, time) => sum + time) / times.length,
          'minTime': times.first,
          'maxTime': times.last,
          'medianTime': times[times.length ~/ 2],
        };
      });

      return stats;
    } catch (e) {
      developer.log('Failed to get performance stats: $e');
      return {};
    }
  }
}
