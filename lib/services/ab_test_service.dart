import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/ab_test.dart';

/// Сервис A/B тестирования
class ABTestService {
  factory ABTestService() => _instance;
  ABTestService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  static final ABTestService _instance = ABTestService._internal();

  final Map<String, ABTestParticipation> _userParticipations = {};

  /// Создать A/B тест
  Future<String> createABTest({
    required String name,
    required String description,
    required List<ABTestVariant> variants,
    required ABTestTargeting targeting,
    required ABTestMetrics metrics,
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
  }) async {
    try {
      final testId = _uuid.v4();
      final now = DateTime.now();

      // Валидация
      if (variants.length < 2) {
        throw Exception('A/B тест должен содержать минимум 2 варианта');
      }

      final totalTraffic =
          variants.fold(0.0, (sum, variant) => sum + variant.trafficPercentage);
      if (totalTraffic > 100.0) {
        throw Exception('Общий трафик вариантов не может превышать 100%');
      }

      final test = ABTest(
        id: testId,
        name: name,
        description: description,
        variants: variants,
        targeting: targeting,
        metrics: metrics,
        startDate: startDate ?? now,
        endDate: endDate,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('abTests').doc(testId).set(test.toMap());

      if (kDebugMode) {
        print('A/B тест создан: $name');
      }

      return testId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания A/B теста: $e');
      }
      rethrow;
    }
  }

  /// Запустить A/B тест
  Future<void> startABTest(String testId) async {
    try {
      final test = await getABTest(testId);
      if (test == null) {
        throw Exception('A/B тест не найден');
      }

      if (!test.canStart) {
        throw Exception('A/B тест не может быть запущен');
      }

      await _firestore.collection('abTests').doc(testId).update({
        'status': ABTestStatus.running.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        print('A/B тест запущен: ${test.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка запуска A/B теста: $e');
      }
      rethrow;
    }
  }

  /// Остановить A/B тест
  Future<void> stopABTest(String testId) async {
    try {
      await _firestore.collection('abTests').doc(testId).update({
        'status': ABTestStatus.completed.toString().split('.').last,
        'endDate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        print('A/B тест остановлен: $testId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка остановки A/B теста: $e');
      }
      rethrow;
    }
  }

  /// Получить A/B тест
  Future<ABTest?> getABTest(String testId) async {
    try {
      final doc = await _firestore.collection('abTests').doc(testId).get();
      if (doc.exists) {
        return ABTest.fromDocument(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения A/B теста: $e');
      }
      return null;
    }
  }

  /// Получить список A/B тестов
  Future<List<ABTest>> getABTests({
    ABTestStatus? status,
    String? createdBy,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('abTests');

      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }
      if (createdBy != null) {
        query = query.where('createdBy', isEqualTo: createdBy);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs.map(ABTest.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения списка A/B тестов: $e');
      }
      return [];
    }
  }

  /// Получить вариант для пользователя
  Future<ABTestVariant?> getUserVariant(String testId, String userId) async {
    try {
      // Проверяем кэш
      final cacheKey = '${testId}_$userId';
      if (_userParticipations.containsKey(cacheKey)) {
        final participation = _userParticipations[cacheKey]!;
        final test = await getABTest(testId);
        if (test != null) {
          return test.variants.firstWhere(
            (variant) => variant.id == participation.variantId,
            orElse: () => test.variants.first,
          );
        }
      }

      // Получаем тест
      final test = await getABTest(testId);
      if (test == null || !test.isActive) {
        return null;
      }

      // Проверяем таргетинг
      if (!_isUserTargeted(test, userId)) {
        return null;
      }

      // Проверяем, участвует ли пользователь уже в тесте
      final existingParticipation = await _getUserParticipation(testId, userId);
      if (existingParticipation != null) {
        _userParticipations[cacheKey] = existingParticipation;
        return test.variants.firstWhere(
          (variant) => variant.id == existingParticipation.variantId,
          orElse: () => test.variants.first,
        );
      }

      // Назначаем вариант
      final variant = _assignVariant(test, userId);
      if (variant != null) {
        await _recordParticipation(testId, userId, variant.id);
        _userParticipations[cacheKey] = ABTestParticipation(
          id: _uuid.v4(),
          testId: testId,
          userId: userId,
          variantId: variant.id,
          assignedAt: DateTime.now(),
        );
      }

      return variant;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения варианта для пользователя: $e');
      }
      return null;
    }
  }

  /// Проверить, таргетирован ли пользователь
  bool _isUserTargeted(ABTest test, String userId) {
    final targeting = test.targeting;

    // Проверяем трафик
    if (_random.nextDouble() * 100 > targeting.trafficPercentage) {
      return false;
    }

    // Проверяем время
    final now = DateTime.now();
    if (targeting.startTime != null && now.isBefore(targeting.startTime!)) {
      return false;
    }
    if (targeting.endTime != null && now.isAfter(targeting.endTime!)) {
      return false;
    }

    // Проверяем конкретных пользователей
    if (targeting.userIds.isNotEmpty && !targeting.userIds.contains(userId)) {
      return false;
    }

    // TODO: Добавить проверку сегментов пользователей, платформ, версий приложения

    return true;
  }

  /// Назначить вариант пользователю
  ABTestVariant? _assignVariant(ABTest test, String userId) {
    if (test.variants.isEmpty) return null;

    // Используем хеш от userId для консистентного назначения
    final hash = userId.hashCode;
    final randomValue = (hash % 10000) / 10000.0;

    var cumulativePercentage = 0;
    for (final variant in test.variants) {
      cumulativePercentage += (variant.trafficPercentage / 100.0).toInt();
      if (randomValue <= cumulativePercentage) {
        return variant;
      }
    }

    // Fallback на первый вариант
    return test.variants.first;
  }

  /// Записать участие пользователя
  Future<void> _recordParticipation(
    String testId,
    String userId,
    String variantId,
  ) async {
    try {
      final participation = ABTestParticipation(
        id: _uuid.v4(),
        testId: testId,
        userId: userId,
        variantId: variantId,
        assignedAt: DateTime.now(),
      );

      await _firestore
          .collection('abTestParticipations')
          .add(participation.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка записи участия в A/B тесте: $e');
      }
    }
  }

  /// Получить участие пользователя
  Future<ABTestParticipation?> _getUserParticipation(
    String testId,
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('abTestParticipations')
          .where('testId', isEqualTo: testId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ABTestParticipation.fromDocument(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения участия пользователя: $e');
      }
      return null;
    }
  }

  /// Записать событие конверсии
  Future<void> recordConversion(
    String testId,
    String userId,
    String eventName,
    Map<String, dynamic>? eventData,
  ) async {
    try {
      final participation = await _getUserParticipation(testId, userId);
      if (participation == null) return;

      final events = Map<String, dynamic>.from(participation.events);
      events[eventName] = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': eventData ?? {},
      };

      await _firestore
          .collection('abTestParticipations')
          .doc(participation.id)
          .update({
        'events': events,
        if (eventName == 'conversion')
          'convertedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        print('Конверсия записана: $testId, $userId, $eventName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка записи конверсии: $e');
      }
    }
  }

  /// Получить статистику A/B теста
  Future<ABTestStatistics> getTestStatistics(String testId) async {
    try {
      final test = await getABTest(testId);
      if (test == null) {
        throw Exception('A/B тест не найден');
      }

      final participations = await _getTestParticipations(testId);
      final statistics = <String, ABTestVariantStatistics>{};

      for (final variant in test.variants) {
        final variantParticipations =
            participations.where((p) => p.variantId == variant.id).toList();
        final conversions =
            variantParticipations.where((p) => p.isConverted).length;
        final conversionRate = variantParticipations.isEmpty
            ? 0.0
            : conversions / variantParticipations.length;

        statistics[variant.id] = ABTestVariantStatistics(
          variantId: variant.id,
          variantName: variant.name,
          participants: variantParticipations.length,
          conversions: conversions,
          conversionRate: conversionRate,
          averageTimeToConversion:
              _calculateAverageTimeToConversion(variantParticipations),
        );
      }

      return ABTestStatistics(
        testId: testId,
        testName: test.name,
        totalParticipants: participations.length,
        totalConversions: participations.where((p) => p.isConverted).length,
        variantStatistics: statistics,
        isStatisticallySignificant:
            _isStatisticallySignificant(statistics, test.metrics),
        confidenceLevel: _calculateConfidenceLevel(statistics),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения статистики A/B теста: $e');
      }
      rethrow;
    }
  }

  /// Получить участия в тесте
  Future<List<ABTestParticipation>> _getTestParticipations(
    String testId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('abTestParticipations')
          .where('testId', isEqualTo: testId)
          .get();

      return snapshot.docs.map(ABTestParticipation.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения участий в тесте: $e');
      }
      return [];
    }
  }

  /// Вычислить среднее время до конверсии
  Duration? _calculateAverageTimeToConversion(
    List<ABTestParticipation> participations,
  ) {
    final convertedParticipations =
        participations.where((p) => p.isConverted).toList();
    if (convertedParticipations.isEmpty) return null;

    final totalTime = convertedParticipations.fold<Duration>(
      Duration.zero,
      (sum, p) => sum + (p.timeToConversion ?? Duration.zero),
    );

    return Duration(
      milliseconds: totalTime.inMilliseconds ~/ convertedParticipations.length,
    );
  }

  /// Проверить статистическую значимость
  bool _isStatisticallySignificant(
    Map<String, ABTestVariantStatistics> statistics,
    ABTestMetrics metrics,
  ) {
    if (statistics.length < 2) return false;

    final variants = statistics.values.toList();
    final controlVariant = variants.firstWhere(
      (v) => v.variantName.toLowerCase().contains('control'),
      orElse: () => variants.first,
    );

    final treatmentVariant = variants.firstWhere(
      (v) => v.variantId != controlVariant.variantId,
      orElse: () => variants.last,
    );

    // Простая проверка на минимальный размер выборки
    if (controlVariant.participants < metrics.minimumSampleSize ||
        treatmentVariant.participants < metrics.minimumSampleSize) {
      return false;
    }

    // Простая проверка на разницу в конверсии
    final conversionDifference =
        (treatmentVariant.conversionRate - controlVariant.conversionRate).abs();
    return conversionDifference >= metrics.minimumDetectableEffect;
  }

  /// Вычислить уровень доверия
  double _calculateConfidenceLevel(
    Map<String, ABTestVariantStatistics> statistics,
  ) {
    // Упрощенный расчет уровня доверия
    if (statistics.length < 2) return 0;

    final variants = statistics.values.toList();
    final controlVariant = variants.firstWhere(
      (v) => v.variantName.toLowerCase().contains('control'),
      orElse: () => variants.first,
    );

    final treatmentVariant = variants.firstWhere(
      (v) => v.variantId != controlVariant.variantId,
      orElse: () => variants.last,
    );

    final conversionDifference =
        (treatmentVariant.conversionRate - controlVariant.conversionRate).abs();
    final minSampleSize = [
      controlVariant.participants,
      treatmentVariant.participants,
    ].reduce((a, b) => a < b ? a : b);

    // Простая формула для уровня доверия
    if (minSampleSize < 100) return 0;
    if (minSampleSize < 500) return 0.5;
    if (minSampleSize < 1000) return 0.7;
    if (minSampleSize < 2000) return 0.8;
    if (minSampleSize < 5000) return 0.9;
    return 0.95;
  }

  /// Обновить A/B тест
  Future<void> updateABTest(String testId, ABTest updatedTest) async {
    try {
      await _firestore.collection('abTests').doc(testId).update({
        ...updatedTest.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        print('A/B тест обновлен: ${updatedTest.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обновления A/B теста: $e');
      }
      rethrow;
    }
  }

  /// Удалить A/B тест
  Future<void> deleteABTest(String testId) async {
    try {
      // Удаляем тест
      await _firestore.collection('abTests').doc(testId).delete();

      // Удаляем участия
      final participations = await _getTestParticipations(testId);
      final batch = _firestore.batch();
      for (final participation in participations) {
        batch.delete(
          _firestore.collection('abTestParticipations').doc(participation.id),
        );
      }
      await batch.commit();

      if (kDebugMode) {
        print('A/B тест удален: $testId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления A/B теста: $e');
      }
      rethrow;
    }
  }

  /// Очистить кэш участий
  void clearParticipationCache() {
    _userParticipations.clear();
  }
}

/// Статистика A/B теста
class ABTestStatistics {
  const ABTestStatistics({
    required this.testId,
    required this.testName,
    required this.totalParticipants,
    required this.totalConversions,
    required this.variantStatistics,
    required this.isStatisticallySignificant,
    required this.confidenceLevel,
  });
  final String testId;
  final String testName;
  final int totalParticipants;
  final int totalConversions;
  final Map<String, ABTestVariantStatistics> variantStatistics;
  final bool isStatisticallySignificant;
  final double confidenceLevel;

  /// Общий коэффициент конверсии
  double get overallConversionRate {
    if (totalParticipants == 0) return 0;
    return totalConversions / totalParticipants;
  }

  /// Лучший вариант
  ABTestVariantStatistics? get winningVariant {
    if (variantStatistics.isEmpty) return null;

    return variantStatistics.values
        .reduce((a, b) => a.conversionRate > b.conversionRate ? a : b);
  }

  @override
  String toString() =>
      'ABTestStatistics(testId: $testId, totalParticipants: $totalParticipants, isSignificant: $isStatisticallySignificant)';
}

/// Статистика варианта A/B теста
class ABTestVariantStatistics {
  const ABTestVariantStatistics({
    required this.variantId,
    required this.variantName,
    required this.participants,
    required this.conversions,
    required this.conversionRate,
    this.averageTimeToConversion,
  });
  final String variantId;
  final String variantName;
  final int participants;
  final int conversions;
  final double conversionRate;
  final Duration? averageTimeToConversion;

  /// Улучшение конверсии в процентах
  double getConversionImprovement(ABTestVariantStatistics baseline) {
    if (baseline.conversionRate == 0) return 0;
    return ((conversionRate - baseline.conversionRate) /
            baseline.conversionRate) *
        100;
  }

  @override
  String toString() =>
      'ABTestVariantStatistics(variantName: $variantName, conversionRate: ${(conversionRate * 100).toStringAsFixed(2)}%)';
}
