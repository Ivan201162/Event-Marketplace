import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для заявок с тестовыми данными
final bookingsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  // Сначала пытаемся загрузить из Firestore
  try {
    await for (final snapshot in FirebaseFirestore.instance
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()) {
      final bookings = snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data(),
            },
          )
          .toList();

      // Если нет данных, добавляем тестовые
      if (bookings.isEmpty) {
        yield _getTestBookings();
      } else {
        yield bookings;
      }
    }
  } on Exception {
    // В случае ошибки возвращаем тестовые данные
    yield _getTestBookings();
  }
});

/// Тестовые данные для заявок
List<Map<String, dynamic>> _getTestBookings() => [
      {
        'id': 'booking_1',
        'customerName': 'Иван Заказчик',
        'customerEmail': 'ivan@example.com',
        'customerPhone': '+7 (999) 123-45-67',
        'specialistName': 'Андрей Ведущий',
        'specialistId': 'specialist_1',
        'eventType': 'Свадьба',
        'eventDate':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'eventTime': '18:00',
        'duration': 4,
        'location': 'Ресторан "Солнце"',
        'guestsCount': 30,
        'status': 'Подтверждено',
        'totalPrice': 50000.0,
        'description':
            'Юбилей на 30 человек в ресторане "Солнце". Нужен ведущий для проведения торжества.',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'booking_2',
        'customerName': 'Мария Организатор',
        'customerEmail': 'maria@example.com',
        'customerPhone': '+7 (999) 234-56-78',
        'specialistName': 'Елена Фотограф',
        'specialistId': 'specialist_2',
        'eventType': 'Корпоратив',
        'eventDate':
            DateTime.now().add(const Duration(days: 15)).toIso8601String(),
        'eventTime': '19:00',
        'duration': 3,
        'location': 'Офис компании',
        'guestsCount': 50,
        'status': 'В обработке',
        'totalPrice': 30000.0,
        'description':
            'Корпоративное мероприятие для сотрудников. Нужна фотосъемка.',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'booking_3',
        'customerName': 'Алексей Клиент',
        'customerEmail': 'alex@example.com',
        'customerPhone': '+7 (999) 345-67-89',
        'specialistName': 'Дмитрий Диджей',
        'specialistId': 'specialist_3',
        'eventType': 'День рождения',
        'eventDate':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'eventTime': '20:00',
        'duration': 5,
        'location': 'Дом клиента',
        'guestsCount': 20,
        'status': 'Завершено',
        'totalPrice': 25000.0,
        'description':
            'День рождения на 20 человек. Нужен диджей для музыкального сопровождения.',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'booking_4',
        'customerName': 'Ольга Заказчица',
        'customerEmail': 'olga@example.com',
        'customerPhone': '+7 (999) 456-78-90',
        'specialistName': 'Сергей Декоратор',
        'specialistId': 'specialist_4',
        'eventType': 'Выпускной',
        'eventDate':
            DateTime.now().add(const Duration(days: 45)).toIso8601String(),
        'eventTime': '17:00',
        'duration': 6,
        'location': 'Школа №123',
        'guestsCount': 100,
        'status': 'Отклонено',
        'totalPrice': 75000.0,
        'description':
            'Выпускной вечер для 11 класса. Нужно украсить актовый зал.',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'booking_5',
        'customerName': 'Николай Клиент',
        'customerEmail': 'nikolay@example.com',
        'customerPhone': '+7 (999) 567-89-01',
        'specialistName': 'Анна Кейтеринг',
        'specialistId': 'specialist_5',
        'eventType': 'Семейный праздник',
        'eventDate':
            DateTime.now().add(const Duration(days: 20)).toIso8601String(),
        'eventTime': '16:00',
        'duration': 4,
        'location': 'Дача клиента',
        'guestsCount': 15,
        'status': 'Подтверждено',
        'totalPrice': 40000.0,
        'description':
            'Семейный праздник на даче. Нужно организовать кейтеринг.',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'updatedAt':
            DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
    ];
