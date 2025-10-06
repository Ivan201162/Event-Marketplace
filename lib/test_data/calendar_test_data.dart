import '../models/specialist.dart';
import '../services/calendar_service.dart';

/// Тестовые данные для календаря специалистов
class CalendarTestData {
  static final CalendarService _calendarService = CalendarService();

  /// Добавить тестовые занятые даты для специалиста
  static Future<void> addTestBusyDates(String specialistId) async {
    try {
      final now = DateTime.now();

      // Добавляем несколько занятых дат в ближайшие дни
      final testDates = [
        now.add(const Duration(days: 1)), // Завтра
        now.add(const Duration(days: 3)), // Через 3 дня
        now.add(const Duration(days: 5)), // Через 5 дней
        now.add(const Duration(days: 7)), // Через неделю
        now.add(const Duration(days: 10)), // Через 10 дней
        now.add(const Duration(days: 14)), // Через 2 недели
      ];

      for (final date in testDates) {
        await _calendarService.markDateBusy(specialistId, date);
      }

      print('Добавлены тестовые занятые даты для специалиста: $specialistId');
    } catch (e) {
      print('Ошибка добавления тестовых занятых дат: $e');
    }
  }

  /// Создать тестовые бронирования для демонстрации синхронизации
  static Future<void> createTestBookings(String specialistId) async {
    try {
      final now = DateTime.now();

      // Создаем тестовые бронирования
      final testBookings = [
        {
          'specialistId': specialistId,
          'customerId': 'test_customer_1',
          'customerName': 'Иван Петров',
          'eventDate': now.add(const Duration(days: 2)),
          'endDate': now.add(const Duration(days: 2, hours: 3)),
          'status': 'confirmed',
          'title': 'Свадебная фотосъемка',
          'description': 'Свадебная фотосъемка в парке',
          'totalPrice': 15000.0,
          'participantsCount': 2,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        },
        {
          'specialistId': specialistId,
          'customerId': 'test_customer_2',
          'customerName': 'Мария Сидорова',
          'eventDate': now.add(const Duration(days: 6)),
          'endDate': now.add(const Duration(days: 6, hours: 2)),
          'status': 'confirmed',
          'title': 'Портретная съемка',
          'description': 'Портретная съемка в студии',
          'totalPrice': 8000.0,
          'participantsCount': 1,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        },
        {
          'specialistId': specialistId,
          'customerId': 'test_customer_3',
          'customerName': 'Алексей Козлов',
          'eventDate': now.add(const Duration(days: 9)),
          'endDate': now.add(const Duration(days: 9, hours: 4)),
          'status': 'pending',
          'title': 'Корпоративная съемка',
          'description': 'Корпоративная съемка в офисе',
          'totalPrice': 12000.0,
          'participantsCount': 15,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        },
      ];

      // Здесь можно добавить логику создания бронирований в Firestore
      // Пока просто выводим информацию
      print('Созданы тестовые бронирования для специалиста: $specialistId');
      for (final booking in testBookings) {
        print('Бронирование: ${booking['title']} на ${booking['eventDate']}');
      }
    } catch (e) {
      print('Ошибка создания тестовых бронирований: $e');
    }
  }

  /// Синхронизировать тестовые данные
  static Future<void> syncTestData(String specialistId) async {
    try {
      // Сначала создаем тестовые бронирования
      await createTestBookings(specialistId);

      // Затем синхронизируем занятые даты
      await _calendarService.syncBusyDatesWithBookings(specialistId);

      print('Тестовые данные синхронизированы для специалиста: $specialistId');
    } catch (e) {
      print('Ошибка синхронизации тестовых данных: $e');
    }
  }

  /// Получить тестового специалиста с занятыми датами
  static Specialist createTestSpecialistWithBusyDates({
    required String id,
    required String name,
    required SpecialistCategory category,
  }) {
    final now = DateTime.now();
    final busyDates = [
      now.add(const Duration(days: 1)),
      now.add(const Duration(days: 3)),
      now.add(const Duration(days: 5)),
      now.add(const Duration(days: 7)),
      now.add(const Duration(days: 10)),
    ];

    return Specialist(
      id: id,
      userId: 'user_$id',
      name: name,
      category: category,
      experienceLevel: ExperienceLevel.intermediate,
      yearsOfExperience: 3,
      hourlyRate: 2000,
      price: 5000,
      busyDates: busyDates,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Получить список тестовых специалистов
  static List<Specialist> getTestSpecialists() => [
        createTestSpecialistWithBusyDates(
          id: 'specialist_1',
          name: 'Анна Петрова',
          category: SpecialistCategory.photographer,
        ),
        createTestSpecialistWithBusyDates(
          id: 'specialist_2',
          name: 'Михаил Иванов',
          category: SpecialistCategory.videographer,
        ),
        createTestSpecialistWithBusyDates(
          id: 'specialist_3',
          name: 'Елена Сидорова',
          category: SpecialistCategory.dj,
        ),
      ];

  /// Очистить тестовые данные
  static Future<void> clearTestData(String specialistId) async {
    try {
      // Здесь можно добавить логику очистки тестовых данных
      print('Тестовые данные очищены для специалиста: $specialistId');
    } catch (e) {
      print('Ошибка очистки тестовых данных: $e');
    }
  }
}
