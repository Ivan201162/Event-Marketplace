import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/specialist.dart';
import '../../../services/specialist_service.dart';

/// Кнопка для создания тест-специалиста с улучшенной обработкой ошибок
class CreateTestSpecialistButton extends ConsumerStatefulWidget {
  const CreateTestSpecialistButton({
    super.key,
    this.onSpecialistCreated,
    this.specialistType,
  });
  final VoidCallback? onSpecialistCreated;
  final String? specialistType;

  @override
  ConsumerState<CreateTestSpecialistButton> createState() => _CreateTestSpecialistButtonState();
}

class _CreateTestSpecialistButtonState extends ConsumerState<CreateTestSpecialistButton> {
  final SpecialistService _specialistService = SpecialistService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isCreating = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_successMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _createTestSpecialist,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add),
              label: Text(
                _isCreating ? 'Создание...' : 'Создать тест-специалиста',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );

  Future<void> _createTestSpecialist() async {
    setState(() {
      _isCreating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final specialistId = _firestore.collection('specialists').doc().id;

      // Создаем валидный объект Specialist с минимальными обязательными полями
      final specialist = _createSpecialistData(specialistId);

      // Сохраняем в Firestore
      await _firestore.collection('specialists').doc(specialistId).set(specialist.toMap());

      setState(() {
        _successMessage = 'Тест-специалист "${specialist.name}" создан успешно!';
      });

      // Вызываем callback если есть
      widget.onSpecialistCreated?.call();

      // Показываем SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Создан тест-специалист: ${specialist.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Очищаем сообщение через 3 секунды
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Ошибка создания тест-специалиста: $e');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        _errorMessage = 'Ошибка создания тест-специалиста: ${_getErrorMessage(e)}';
      });

      // Показываем SnackBar с ошибкой
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${_getErrorMessage(e)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  /// Создание данных специалиста в зависимости от типа
  Specialist _createSpecialistData(String specialistId) {
    final now = DateTime.now();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'test_user_$specialistId';

    switch (widget.specialistType) {
      case 'photographer':
        return _createPhotographer(specialistId, userId, now);
      case 'videographer':
        return _createVideographer(specialistId, userId, now);
      case 'dj':
        return _createDJ(specialistId, userId, now);
      case 'host':
        return _createHost(specialistId, userId, now);
      default:
        return _createDefaultSpecialist(specialistId, userId, now);
    }
  }

  /// Создание фотографа
  Specialist _createPhotographer(
    String specialistId,
    String userId,
    DateTime now,
  ) =>
      Specialist(
        id: specialistId,
        userId: userId,
        name: 'Анна Фотограф',
        description:
            'Профессиональный фотограф с 5-летним опытом. Специализируюсь на свадебной и портретной фотографии.',
        bio: 'Люблю создавать красивые моменты и запечатлевать эмоции. Работаю в Москве и области.',
        category: SpecialistCategory.photographer,
        experienceLevel: ExperienceLevel.intermediate,
        yearsOfExperience: 5,
        hourlyRate: 3000,
        price: 3000,
        location: 'Москва',
        imageUrl:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
        isVerified: true,
        rating: 4.8,
        reviewCount: 127,
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now,
        contacts: {
          'Телефон': '+7 (999) 123-45-67',
          'Email': 'anna.photographer@example.com',
          'Instagram': '@anna_photographer',
          'VK': 'vk.com/anna_photographer',
        },
        servicesWithPrices: {
          'Свадебная фотосессия': 50000.0,
          'Портретная фотосессия': 15000.0,
          'Семейная фотосессия': 20000.0,
          'Корпоративная съемка': 25000.0,
          'Love Story': 12000.0,
        },
      );

  /// Создание видеографа
  Specialist _createVideographer(
    String specialistId,
    String userId,
    DateTime now,
  ) =>
      Specialist(
        id: specialistId,
        userId: userId,
        name: 'Максим Видеограф',
        description:
            'Креативный видеограф и монтажер. Создаю запоминающиеся видео для любых событий.',
        bio:
            '5 лет в индустрии видео. Работаю с современным оборудованием и программным обеспечением.',
        category: SpecialistCategory.videographer,
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 5,
        hourlyRate: 4000,
        price: 4000,
        location: 'Санкт-Петербург',
        imageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        isVerified: true,
        rating: 4.9,
        reviewCount: 89,
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now,
        contacts: {
          'Телефон': '+7 (812) 555-12-34',
          'Email': 'max.videographer@example.com',
          'Instagram': '@max_videographer',
          'Telegram': '@max_video',
        },
        servicesWithPrices: {
          'Свадебное видео': 80000.0,
          'Корпоративное видео': 60000.0,
          'Промо-ролик': 40000.0,
          'Монтаж видео': 15000.0,
          'Аэросъемка': 25000.0,
        },
      );

  /// Создание DJ
  Specialist _createDJ(String specialistId, String userId, DateTime now) => Specialist(
        id: specialistId,
        userId: userId,
        name: 'DJ Алексей',
        description:
            'Профессиональный DJ с 8-летним опытом. Специализируюсь на свадьбах и корпоративных мероприятиях.',
        bio:
            'Создаю атмосферу праздника с помощью качественной музыки и современного оборудования.',
        category: SpecialistCategory.dj,
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 8,
        hourlyRate: 5000,
        price: 5000,
        location: 'Москва',
        imageUrl:
            'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400&h=400&fit=crop&crop=face',
        isVerified: true,
        rating: 4.7,
        reviewCount: 156,
        createdAt: now.subtract(const Duration(days: 500)),
        updatedAt: now,
        contacts: {
          'Телефон': '+7 (495) 123-45-67',
          'Email': 'dj.alexey@example.com',
          'Instagram': '@dj_alexey',
          'VK': 'vk.com/dj_alexey',
        },
        servicesWithPrices: {
          'Свадебный DJ': 40000.0,
          'Корпоративный DJ': 35000.0,
          'День рождения': 25000.0,
          'Клубный вечер': 30000.0,
          'Аренда оборудования': 15000.0,
        },
      );

  /// Создание ведущего
  Specialist _createHost(String specialistId, String userId, DateTime now) => Specialist(
        id: specialistId,
        userId: userId,
        name: 'Ведущий Дмитрий',
        description:
            'Опытный ведущий мероприятий. Специализируюсь на свадьбах, корпоративах и детских праздниках.',
        bio:
            'Создаю незабываемые моменты и веселье для всех гостей. Индивидуальный подход к каждому мероприятию.',
        category: SpecialistCategory.host,
        experienceLevel: ExperienceLevel.expert,
        yearsOfExperience: 10,
        hourlyRate: 6000,
        price: 6000,
        location: 'Москва',
        imageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        isVerified: true,
        rating: 4.9,
        reviewCount: 203,
        createdAt: now.subtract(const Duration(days: 800)),
        updatedAt: now,
        contacts: {
          'Телефон': '+7 (495) 987-65-43',
          'Email': 'host.dmitry@example.com',
          'Instagram': '@host_dmitry',
          'VK': 'vk.com/host_dmitry',
        },
        servicesWithPrices: {
          'Свадебный ведущий': 60000.0,
          'Корпоративный ведущий': 50000.0,
          'Детский праздник': 30000.0,
          'День рождения': 40000.0,
          'Консультация': 5000.0,
        },
      );

  /// Создание специалиста по умолчанию
  Specialist _createDefaultSpecialist(
    String specialistId,
    String userId,
    DateTime now,
  ) =>
      Specialist(
        id: specialistId,
        userId: userId,
        name: 'Тест Специалист',
        description: 'Тестовый специалист для проверки функциональности приложения.',
        bio: 'Это тестовый профиль, созданный для демонстрации возможностей приложения.',
        category: SpecialistCategory.other,
        experienceLevel: ExperienceLevel.beginner,
        yearsOfExperience: 1,
        hourlyRate: 1000,
        price: 1000,
        location: 'Тестовый город',
        imageUrl:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
        createdAt: now,
        updatedAt: now,
        contacts: {
          'Телефон': '+7 (999) 000-00-00',
          'Email': 'test@example.com',
        },
        servicesWithPrices: {
          'Тестовая услуга': 5000.0,
        },
      );

  /// Получение понятного сообщения об ошибке
  String _getErrorMessage(error) {
    if (error.toString().contains('permission-denied')) {
      return 'Нет прав доступа к базе данных';
    } else if (error.toString().contains('network')) {
      return 'Ошибка сети. Проверьте подключение к интернету';
    } else if (error.toString().contains('timeout')) {
      return 'Превышено время ожидания';
    } else if (error.toString().contains('invalid-argument')) {
      return 'Некорректные данные';
    } else {
      return error.toString();
    }
  }
}
