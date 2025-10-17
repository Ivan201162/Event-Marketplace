import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Сервис для создания тестовых данных в Firestore
class FirestoreSeederService {
  factory FirestoreSeederService() => _instance;
  FirestoreSeederService._internal();
  static final FirestoreSeederService _instance =
      FirestoreSeederService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создание тестовых данных
  Future<bool> seedTestData() async {
    try {
      debugPrint('🌱 Начинаем создание тестовых данных...');
      final now = DateTime.now();

      // Users (2 клиента, 2 специалиста)
      debugPrint('👥 Создание пользователей...');
      final users = [
        {
          'id': 'u_customer_1',
          'name': 'Иван Петров',
          'city': 'Москва',
          'role': 'customer',
        },
        {
          'id': 'u_customer_2',
          'name': 'Елена Смирнова',
          'city': 'СПб',
          'role': 'customer',
        },
        {
          'id': 'u_spec_1',
          'name': 'Ведущий Артём',
          'city': 'Москва',
          'role': 'specialist',
        },
        {
          'id': 'u_spec_2',
          'name': 'Фотограф Анна',
          'city': 'СПб',
          'role': 'specialist',
        },
      ];

      for (final u in users) {
        await _firestore.collection('users').doc(u['id']).set(
          {
            'name': u['name'],
            'city': u['city'],
            'role': u['role'],
            'about': 'Тестовый пользователь',
            'email': '${u['id']}@example.com',
            'phone': '+7 (999) 123-45-67',
            'avatar': 'https://picsum.photos/seed/${u['id']}/200/200',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        debugPrint('  ✅ Пользователь ${u['name']} создан');
      }

      // Ideas (фото + видео)
      debugPrint('💡 Создание идей...');
      final ideas = List.generate(
        6,
        (i) => {
          'title': 'Идея #${i + 1}',
          'description':
              'Описание идеи #${i + 1}. Это отличная идея для вашего мероприятия!',
          'category': i.isEven ? 'Фото' : 'Видео',
          'isVideo': i.isOdd,
          'mediaUrl': i.isOdd
              ? 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4'
              : 'https://picsum.photos/seed/idea${i + 1}/600/800',
          'authorId': i.isEven ? 'u_spec_1' : 'u_spec_2',
          'authorName': i.isEven ? 'Ведущий Артём' : 'Фотограф Анна',
          'authorAvatar': 'https://picsum.photos/seed/author${i + 1}/100/100',
          'likes': <String>[],
          'savedBy': <String>[],
          'tags': ['тест', 'идея', if (i.isEven) 'фото' else 'видео'],
          'isPublic': true,
          'likesCount': 0,
          'commentsCount': 0,
          'savesCount': 0,
          'sharesCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      for (var i = 0; i < ideas.length; i++) {
        final idea = ideas[i];
        final ref = await _firestore.collection('ideas').add(idea);
        debugPrint('  ✅ Идея ${idea['title']} создана с ID: ${ref.id}');

        // Добавляем комментарий к каждой идее
        await ref.collection('comments').add({
          'text': 'Отличная идея! Очень понравилось.',
          'authorId': 'u_customer_1',
          'authorName': 'Иван Петров',
          'authorAvatar': 'https://picsum.photos/seed/user1/50/50',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'likesCount': 0,
          'likedBy': <String>[],
        });
        debugPrint('    💬 Комментарий добавлен');
      }

      // Chats (один чат и пару сообщений)
      debugPrint('💬 Создание чатов...');
      final chatRef = _firestore.collection('chats').doc('c_demo_1');
      await chatRef.set({
        'members': ['u_customer_1', 'u_spec_1'],
        'lastMessage': 'Добрый день, чем могу помочь?',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('  ✅ Чат c_demo_1 создан');

      // Сообщения в чате
      await chatRef.collection('messages').add({
        'senderId': 'u_customer_1',
        'senderName': 'Иван Петров',
        'type': 'text',
        'text': 'Здравствуйте!',
        'sentAt': FieldValue.serverTimestamp(),
      });

      await chatRef.collection('messages').add({
        'senderId': 'u_spec_1',
        'senderName': 'Ведущий Артём',
        'type': 'text',
        'text': 'Добрый день, чем могу помочь?',
        'sentAt': FieldValue.serverTimestamp(),
      });
      debugPrint('  💬 2 сообщения добавлены в чат');

      // Bookings (2 заявки)
      debugPrint('📋 Создание заявок...');
      await _firestore.collection('bookings').add({
        'customerId': 'u_customer_1',
        'customerName': 'Иван Петров',
        'specialistId': 'u_spec_1',
        'specialistName': 'Ведущий Артём',
        'eventTitle': 'Свадьба Ивана и Марии',
        'eventDate': Timestamp.fromDate(now.add(const Duration(days: 10))),
        'status': 'pending',
        'prepayment': 15000.0,
        'totalPrice': 50000.0,
        'message': 'Хотелось бы обсудить детали свадьбы',
        'participantsCount': 50,
        'address': 'Москва, ул. Тверская, 1',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('  ✅ Заявка #1 создана (Свадьба)');

      await _firestore.collection('bookings').add({
        'customerId': 'u_customer_2',
        'customerName': 'Елена Смирнова',
        'specialistId': 'u_spec_2',
        'specialistName': 'Фотограф Анна',
        'eventTitle': 'День рождения дочери',
        'eventDate': Timestamp.fromDate(now.add(const Duration(days: 20))),
        'status': 'confirmed',
        'prepayment': 20000.0,
        'totalPrice': 70000.0,
        'message': 'Нужна фотосессия для детского праздника',
        'participantsCount': 15,
        'address': 'СПб, Невский проспект, 100',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('  ✅ Заявка #2 создана (День рождения)');

      // Specialists (дополнительные данные для специалистов)
      debugPrint('👨‍💼 Создание профилей специалистов...');
      await _firestore.collection('specialists').doc('u_spec_1').set(
        {
          'userId': 'u_spec_1',
          'name': 'Ведущий Артём',
          'category': 'Ведущий',
          'city': 'Москва',
          'rating': 4.8,
          'reviewsCount': 25,
          'pricePerHour': 5000.0,
          'description':
              'Опытный ведущий с 5-летним стажем. Провожу свадьбы, корпоративы, дни рождения.',
          'skills': ['Свадьбы', 'Корпоративы', 'Дни рождения'],
          'portfolio': [
            'https://picsum.photos/seed/portfolio1/300/200',
            'https://picsum.photos/seed/portfolio2/300/200',
            'https://picsum.photos/seed/portfolio3/300/200',
          ],
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _firestore.collection('specialists').doc('u_spec_2').set(
        {
          'userId': 'u_spec_2',
          'name': 'Фотограф Анна',
          'category': 'Фотограф',
          'city': 'СПб',
          'rating': 4.9,
          'reviewsCount': 40,
          'pricePerHour': 3000.0,
          'description':
              'Профессиональный фотограф. Специализируюсь на свадебной и семейной фотографии.',
          'skills': [
            'Свадебная фотосъемка',
            'Семейная фотосъемка',
            'Детская фотосъемка',
          ],
          'portfolio': [
            'https://picsum.photos/seed/photo1/300/200',
            'https://picsum.photos/seed/photo2/300/200',
            'https://picsum.photos/seed/photo3/300/200',
          ],
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('  ✅ Профили специалистов созданы');

      debugPrint('✅ Seeder: тестовые данные успешно созданы');
      debugPrint('📊 Создано:');
      debugPrint('  - 4 пользователя');
      debugPrint('  - 6 идей с комментариями');
      debugPrint('  - 1 чат с 2 сообщениями');
      debugPrint('  - 2 заявки');
      debugPrint('  - 2 профиля специалистов');

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при создании тестовых данных: $e');
      return false;
    }
  }

  /// Проверка наличия тестовых данных
  Future<bool> hasTestData() async {
    try {
      final ideasSnapshot = await _firestore.collection('ideas').limit(1).get();
      final chatsSnapshot = await _firestore.collection('chats').limit(1).get();
      final bookingsSnapshot =
          await _firestore.collection('bookings').limit(1).get();

      return ideasSnapshot.docs.isNotEmpty ||
          chatsSnapshot.docs.isNotEmpty ||
          bookingsSnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Ошибка проверки тестовых данных: $e');
      return false;
    }
  }
}

