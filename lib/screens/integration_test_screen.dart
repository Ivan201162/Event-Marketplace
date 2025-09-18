import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firestore_providers.dart';
import '../providers/calendar_providers.dart';
import '../models/booking.dart';

/// Экран для тестирования интеграции всех компонентов
class IntegrationTestScreen extends ConsumerStatefulWidget {
  const IntegrationTestScreen({super.key});

  @override
  ConsumerState<IntegrationTestScreen> createState() =>
      _IntegrationTestScreenState();
}

class _IntegrationTestScreenState extends ConsumerState<IntegrationTestScreen> {
  final String testSpecialistId = 'test_specialist_1';
  final String testCustomerId = 'test_customer_1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тестирование интеграции'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              'Тестирование функционала',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Тест занятых дат
            _buildTestCard(
              title: 'Тест занятых дат',
              description: 'Проверка получения занятых дат из Firestore',
              onTest: _testBusyDates,
            ),

            const SizedBox(height: 16),

            // Тест календаря
            _buildTestCard(
              title: 'Тест календаря',
              description: 'Проверка интеграции календаря с занятыми датами',
              onTest: _testCalendarIntegration,
            ),

            const SizedBox(height: 16),

            // Тест бронирования
            _buildTestCard(
              title: 'Тест бронирования',
              description:
                  'Проверка создания бронирования с проверкой конфликтов',
              onTest: _testBookingCreation,
            ),

            const SizedBox(height: 16),

            // Тест FCM
            _buildTestCard(
              title: 'Тест FCM',
              description: 'Проверка отправки push-уведомлений',
              onTest: _testFCM,
            ),

            const SizedBox(height: 16),

            // Тест Cloud Functions
            _buildTestCard(
              title: 'Тест Cloud Functions',
              description: 'Проверка работы Cloud Functions (симуляция)',
              onTest: _testCloudFunctions,
            ),

            const SizedBox(height: 24),

            // Результаты тестов
            _buildTestResults(),
          ],
        ),
      ),
    );
  }

  /// Построить карточку теста
  Widget _buildTestCard({
    required String title,
    required String description,
    required VoidCallback onTest,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTest,
                child: const Text('Запустить тест'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить результаты тестов
  Widget _buildTestResults() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Результаты тестов',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Здесь будут отображаться результаты тестов
            const Text('Запустите тесты для просмотра результатов'),
          ],
        ),
      ),
    );
  }

  /// Тест занятых дат
  Future<void> _testBusyDates() async {
    try {
      final busyDates = await ref
          .read(firestoreServiceProvider)
          .getBusyDates(testSpecialistId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Занятые даты получены: ${busyDates.length} дат'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка получения занятых дат: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Тест интеграции календаря
  Future<void> _testCalendarIntegration() async {
    try {
      final calendarService = ref.read(calendarServiceProvider);
      final isAvailable = await calendarService.isDateAvailable(
        testSpecialistId,
        DateTime.now().add(const Duration(days: 1)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Календарь работает: дата ${isAvailable ? 'доступна' : 'занята'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка календаря: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Тест создания бронирования
  Future<void> _testBookingCreation() async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final testDate = DateTime.now().add(const Duration(days: 2));

      // Проверяем конфликты
      final hasConflict = await firestoreService.hasBookingConflict(
        testSpecialistId,
        testDate,
        testDate.add(const Duration(hours: 2)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Проверка конфликтов: ${hasConflict ? 'есть конфликт' : 'конфликтов нет'}'),
            backgroundColor: hasConflict ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка проверки бронирования: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Тест FCM
  Future<void> _testFCM() async {
    try {
      final fcmService = ref.read(fcmServiceProvider);

      // Отправляем тестовое уведомление
      await fcmService.sendBookingNotification(
        userId: testCustomerId,
        title: 'Тестовое уведомление',
        body: 'Это тестовое уведомление для проверки FCM',
        bookingId: 'test_booking_1',
        type: 'test',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FCM уведомление отправлено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка FCM: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Тест Cloud Functions (симуляция)
  Future<void> _testCloudFunctions() async {
    try {
      // Симулируем создание бронирования для тестирования Cloud Functions
      final testBooking = Booking(
        id: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
        eventId: 'test_event_1',
        eventTitle: 'Тестовое событие',
        userId: testCustomerId,
        userName: 'Тестовый клиент',
        userEmail: 'test@example.com',
        userPhone: '+7 (999) 123-45-67',
        status: BookingStatus.pending,
        bookingDate: DateTime.now(),
        eventDate: DateTime.now().add(const Duration(days: 3)),
        participantsCount: 2,
        totalPrice: 5000,
        notes: 'Тестовое бронирование',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customerId: testCustomerId,
        specialistId: testSpecialistId,
        endDate: DateTime.now().add(const Duration(days: 3, hours: 2)),
        prepayment: 1000,
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.addOrUpdateBookingWithCalendar(testBooking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Тестовое бронирование создано (Cloud Functions сработают автоматически)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания тестового бронирования: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
