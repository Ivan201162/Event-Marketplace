import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/customer_portfolio.dart';
import '../models/order_history.dart';
import '../services/anniversary_notification_service.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/customer_portfolio_service.dart';

/// Тестовый экран для проверки функций портфолио заказчика
class PortfolioTestScreen extends StatefulWidget {
  const PortfolioTestScreen({super.key});

  @override
  State<PortfolioTestScreen> createState() => _PortfolioTestScreenState();
}

class _PortfolioTestScreenState extends State<PortfolioTestScreen> {
  final CustomerPortfolioService _portfolioService = CustomerPortfolioService();
  final BookingService _bookingService = BookingService();
  final AnniversaryNotificationService _notificationService = AnniversaryNotificationService();
  final AuthService _authService = AuthService();

  String _testResults = '';
  bool _isRunningTests = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
    } on Exception catch (e) {
      _addTestResult('Ошибка инициализации сервисов: $e');
    }
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults += '${DateTime.now().toString().substring(11, 19)}: $result\n';
    });
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = '';
    });

    _addTestResult('🚀 Начало тестирования портфолио заказчика');

    try {
      await _testPortfolioCreation();
      await _testOrderHistory();
      await _testFavorites();
      await _testAnniversaries();
      await _testNotifications();
      await _testIntegration();

      _addTestResult('✅ Все тесты завершены успешно!');
    } on Exception catch (e) {
      _addTestResult('❌ Ошибка тестирования: $e');
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Future<void> _testPortfolioCreation() async {
    _addTestResult('📋 Тест 1: Создание портфолио заказчика');

    try {
      final currentUser = _authService.currentUser;

      // Создаем тестовое портфолио
      final testPortfolio = CustomerPortfolio(
        id: currentUser.uid,
        name: 'Тестовый Заказчик',
        email: currentUser.email ?? 'test@example.com',
        phoneNumber: '+7 (999) 123-45-67',
        maritalStatus: MaritalStatus.married,
        weddingDate: DateTime(2020, 6, 15),
        partnerName: 'Тестовая Партнерша',
        favoriteSpecialists: ['specialist1', 'specialist2'],
        anniversaries: [
          DateTime(2020, 6, 15), // Свадьба
          DateTime(2021), // Новый год
        ],
        notes: 'Тестовые заметки для портфолио',
        anniversaryRemindersEnabled: true,
        createdAt: DateTime.now(),
      );

      await _portfolioService.createOrUpdatePortfolio(testPortfolio);
      _addTestResult('✅ Портфолио создано успешно');

      // Проверяем загрузку
      final loadedPortfolio = await _portfolioService.getCustomerPortfolio(currentUser.uid);
      if (loadedPortfolio == null) {
        throw Exception('Портфолио не загружено');
      }

      _addTestResult('✅ Портфолио загружено: ${loadedPortfolio.name}');
      _addTestResult(
        '✅ Избранных специалистов: ${loadedPortfolio.favoriteSpecialists.length}',
      );
      _addTestResult('✅ Годовщин: ${loadedPortfolio.anniversaries.length}');
    } on Exception catch (e) {
      _addTestResult('❌ Ошибка создания портфолио: $e');
    }
  }

  Future<void> _testOrderHistory() async {
    _addTestResult('📦 Тест 2: История заказов');

    try {
      final currentUser = _authService.currentUser;

      // Создаем тестовый заказ
      final testOrder = OrderHistory(
        id: 'test_order_${DateTime.now().millisecondsSinceEpoch}',
        specialistId: 'specialist1',
        specialistName: 'Тестовый Специалист',
        serviceName: 'Фотосъемка свадьбы',
        date: DateTime.now().subtract(const Duration(days: 30)),
        price: 50000,
        status: 'completed',
        eventType: 'wedding',
        location: 'Москва',
        notes: 'Отличная съемка!',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        additionalData: {
          'participantsCount': 2,
          'originalPrice': 60000.0,
          'discount': 16.67,
          'finalPrice': 50000.0,
        },
      );

      await _portfolioService.addOrderToHistory(currentUser.uid, testOrder);
      _addTestResult('✅ Заказ добавлен в историю');

      // Проверяем загрузку истории
      final orderHistory = await _portfolioService.getOrderHistory(currentUser.uid);
      _addTestResult(
        '✅ История заказов загружена: ${orderHistory.length} заказов',
      );

      if (orderHistory.isNotEmpty) {
        final lastOrder = orderHistory.first;
        _addTestResult(
          '✅ Последний заказ: ${lastOrder.serviceName} за ${lastOrder.formattedPrice}',
        );
        _addTestResult(
          '✅ Скидка: ${lastOrder.discountAmount.toStringAsFixed(0)} ₽',
        );
      }
    } on Exception catch (e) {
      _addTestResult('❌ Ошибка тестирования истории заказов: $e');
    }
  }

  Future<void> _testFavorites() async {
    _addTestResult('❤️ Тест 3: Избранные специалисты');

    try {
      final currentUser = _authService.currentUser;

      // Добавляем специалиста в избранное
      const testSpecialistId = 'test_specialist_123';
      await _portfolioService.addToFavorites(currentUser.uid, testSpecialistId);
      _addTestResult('✅ Специалист добавлен в избранное');

      // Проверяем статус
      final isFavorite = await _portfolioService.isFavoriteSpecialist(
        currentUser.uid,
        testSpecialistId,
      );
      if (!isFavorite) {
        throw Exception('Специалист не найден в избранном');
      }
      _addTestResult('✅ Специалист найден в избранном');

      // Получаем список избранных
      final favorites = await _portfolioService.getFavoriteSpecialists(currentUser.uid);
      _addTestResult('✅ Избранных специалистов: ${favorites.length}');

      // Удаляем из избранного
      await _portfolioService.removeFromFavorites(
        currentUser.uid,
        testSpecialistId,
      );
      _addTestResult('✅ Специалист удален из избранного');
    } on Exception catch (e) {
      _addTestResult('❌ Ошибка тестирования избранного: $e');
    }
  }

  Future<void> _testAnniversaries() async {
    _addTestResult('📅 Тест 4: Годовщины');

    try {
      final currentUser = _authService.currentUser;

      // Добавляем годовщину
      final testAnniversary = DateTime(2022, 12, 25);
      await _portfolioService.addAnniversary(currentUser.uid, testAnniversary);
      _addTestResult(
        '✅ Годовщина добавлена: ${testAnniversary.day}.${testAnniversary.month}.${testAnniversary.year}',
      );

      // Получаем список годовщин
      final anniversaries = await _portfolioService.getAnniversaries(currentUser.uid);
      _addTestResult('✅ Годовщин в портфолио: ${anniversaries.length}');

      // Проверяем ближайшие годовщины
      final portfolio = await _portfolioService.getCustomerPortfolio(currentUser.uid);
      if (portfolio != null) {
        final upcoming = portfolio.upcomingAnniversaries;
        _addTestResult('✅ Ближайших годовщин: ${upcoming.length}');

        if (upcoming.isNotEmpty) {
          final next = upcoming.first;
          final daysUntil = next.difference(DateTime.now()).inDays;
          _addTestResult('✅ До следующей годовщины: $daysUntil дней');
        }
      }
    } on Exception catch (e) {
      _addTestResult('❌ Ошибка тестирования годовщин: $e');
    }
  }

  Future<void> _testNotifications() async {
    _addTestResult('🔔 Тест 5: Уведомления');

    try {
      // Отправляем тестовое уведомление
      await _notificationService.sendTestNotification();
      _addTestResult('✅ Тестовое уведомление отправлено');

      // Проверяем разрешения
      final hasPermissions = await _notificationService.requestPermissions();
      _addTestResult(
        '✅ Разрешения на уведомления: ${hasPermissions ? "предоставлены" : "отклонены"}',
      );
    } on Exception catch (e) {
      _addTestResult('❌ Ошибка тестирования уведомлений: $e');
    }
  }

  Future<void> _testIntegration() async {
    _addTestResult('🔗 Тест 6: Интеграция с бронированиями');

    try {
      final currentUser = _authService.currentUser;

      // Создаем тестовое бронирование
      final testBooking = Booking(
        id: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
        eventId: 'test_event',
        eventTitle: 'Тестовое мероприятие',
        userId: currentUser.uid,
        userName: 'Тестовый Заказчик',
        userEmail: currentUser.email,
        status: BookingStatus.completed,
        bookingDate: DateTime.now(),
        eventDate: DateTime.now().subtract(const Duration(days: 1)),
        participantsCount: 2,
        totalPrice: 30000,
        specialistId: 'test_specialist',
        specialistName: 'Тестовый Специалист',
        serviceName: 'Тестовая услуга',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      );

      // Добавляем в портфолио через сервис бронирований
      await _bookingService.addBookingToHistory(currentUser.uid, testBooking);
      _addTestResult('✅ Бронирование добавлено в портфолио');

      // Проверяем статистику
      final stats = await _portfolioService.getPortfolioStats(currentUser.uid);
      _addTestResult('✅ Статистика портфолио:');
      _addTestResult('   - Всего заказов: ${stats['totalOrders']}');
      _addTestResult('   - Завершенных: ${stats['completedOrders']}');
      _addTestResult(
        '   - Потрачено: ${stats['totalSpent']?.toStringAsFixed(0)} ₽',
      );
      _addTestResult(
        '   - Средний чек: ${stats['averageOrderValue']?.toStringAsFixed(0)} ₽',
      );

      // Проверяем рекомендации
      final recommendations = await _portfolioService.getRecommendations(currentUser.uid);
      _addTestResult('✅ Рекомендаций: ${recommendations.length}');
      for (final recommendation in recommendations) {
        _addTestResult('   - $recommendation');
      }
    } on Exception catch (e) {
      _addTestResult('❌ Ошибка тестирования интеграции: $e');
    }
  }

  Future<void> _testNotes() async {
    _addTestResult('📝 Тест 7: Заметки');

    try {
      final currentUser = _authService.currentUser;

      const testNotes = 'Это тестовые заметки для проверки функционала портфолио заказчика.';
      await _portfolioService.updateNotes(currentUser.uid, testNotes);
      _addTestResult('✅ Заметки обновлены');

      final loadedNotes = await _portfolioService.getNotes(currentUser.uid);
      if (loadedNotes != testNotes) {
        throw Exception('Заметки не совпадают');
      }
      _addTestResult('✅ Заметки загружены корректно');
    } on Exception catch (e) {
      _addTestResult('❌ Ошибка тестирования заметок: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тестирование портфолио'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _isRunningTests ? null : _runAllTests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isRunningTests
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Тестирование...'),
                            ],
                          )
                        : const Text('Запустить все тесты'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isRunningTests ? null : _testNotes,
                          child: const Text('Тест заметок'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isRunningTests
                              ? null
                              : () async {
                                  await _notificationService.sendTestNotification();
                                  _addTestResult(
                                    '🔔 Тестовое уведомление отправлено',
                                  );
                                },
                          child: const Text('Тест уведомлений'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty
                        ? 'Нажмите "Запустить все тесты" для начала тестирования'
                        : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
