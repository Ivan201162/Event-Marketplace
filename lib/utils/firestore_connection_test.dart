import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Утилита для проверки соединения с Firestore
class FirestoreConnectionTest {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isConnected = false;
  static int _retryCount = 0;
  static const int _maxRetries = 3;

  /// Проверка соединения с Firestore
  static Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Проверка соединения с Firestore...');

      // Простой запрос для проверки соединения
      final snapshot = await _firestore
          .collection('ping_test')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      _isConnected = true;
      _retryCount = 0;
      debugPrint('✅ Firestore connection OK: ${snapshot.size} docs');
      return true;
    } catch (e) {
      _isConnected = false;
      _retryCount++;
      debugPrint('❌ Firestore connection failed: $e');

      if (_retryCount < _maxRetries) {
        debugPrint(
          '🔄 Повторная попытка через 3 секунды... ($_retryCount/$_maxRetries)',
        );
        await Future.delayed(const Duration(seconds: 3));
        return testConnection();
      } else {
        debugPrint('❌ Максимальное количество попыток достигнуто');
        return false;
      }
    }
  }

  /// Проверка соединения с повторными попытками
  static Future<void> ensureConnection() async {
    if (!_isConnected) {
      await testConnection();
    }
  }

  /// Получение статуса соединения
  static bool get isConnected => _isConnected;

  /// Сброс статуса соединения
  static void reset() {
    _isConnected = false;
    _retryCount = 0;
  }

  /// Тест записи в Firestore
  static Future<bool> testWrite() async {
    try {
      debugPrint('🔍 Тест записи в Firestore...');

      await _firestore
          .collection('ping_test')
          .doc('test_${DateTime.now().millisecondsSinceEpoch}')
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
      });

      debugPrint('✅ Firestore write test OK');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore write test failed: $e');
      return false;
    }
  }

  /// Тест чтения из Firestore
  static Future<bool> testRead() async {
    try {
      debugPrint('🔍 Тест чтения из Firestore...');

      final snapshot = await _firestore.collection('ping_test').limit(5).get();

      debugPrint('✅ Firestore read test OK: ${snapshot.docs.length} docs');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore read test failed: $e');
      return false;
    }
  }

  /// Полный тест Firestore (чтение + запись)
  static Future<bool> fullTest() async {
    debugPrint('🚀 Запуск полного теста Firestore...');

    final readTest = await testRead();
    final writeTest = await testWrite();

    final success = readTest && writeTest;

    if (success) {
      debugPrint('✅ Полный тест Firestore пройден успешно');
    } else {
      debugPrint('❌ Полный тест Firestore провален');
    }

    return success;
  }
}



