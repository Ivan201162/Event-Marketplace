import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/specialist_enhanced.dart';

/// Сервис для создания тестовых данных специалистов
class TestSpecialistsDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать тестовых специалистов
  static Future<void> createTestSpecialists() async {
    try {
      final specialists = _generateTestSpecialists();

      for (final specialist in specialists) {
        await _firestore
            .collection('specialists')
            .doc(specialist.id)
            .set(specialist.toFirestore());
      }

      print('✅ Test specialists created successfully');
    } catch (e) {
      print('❌ Error creating test specialists: $e');
    }
  }

  /// Генерировать тестовых специалистов
  static List<SpecialistEnhanced> _generateTestSpecialists() {
    return [
      // Ведущие
      SpecialistEnhanced(
        id: 'specialist_1',
        name: 'Александр Петров',
        specialization: 'Ведущий мероприятий',
        city: 'Москва',
        region: 'Россия',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        bio:
            'Профессиональный ведущий с 10-летним опытом. Провожу свадьбы, корпоративы, детские праздники.',
        rating: 4.9,
        totalOrders: 156,
        successfulOrders: 152,
        categories: ['Ведущие'],
        languages: ['Русский', 'Английский'],
        pricing: {
          'свадьба': 50000.0,
          'корпоратив': 40000.0,
          'детский_праздник': 25000.0,
        },
        availableDates: ['2024-11-15', '2024-11-16', '2024-11-17'],
        imageUrls: [
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400&h=300&fit=crop',
          'https://images.unsplash.com/photo-1464366400600-7168b8af9bc8?w=400&h=300&fit=crop',
        ],
        isVerified: true,
        isTopWeek: true,
        isNewcomer: false,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
        location: {
          'latitude': 55.7558,
          'longitude': 37.6176,
          'address': 'Москва, Красная площадь',
        },
        socialLinks: {
          'instagram': '@alex_petrov_mc',
          'telegram': '@alex_petrov',
        },
        skills: ['Ораторское мастерство', 'Импровизация', 'Работа с детьми'],
        experience: '10 лет',
        education: 'МГУ, факультет журналистики',
        reviews: [
          Review(
            id: 'review_1',
            userId: 'user_1',
            userName: 'Анна Смирнова',
            userAvatar:
                'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=50&h=50&fit=crop&crop=face',
            rating: 5,
            comment: 'Отличный ведущий! Все прошло идеально.',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            images: [],
          ),
        ],
        stats: {
          'responseTime': '2 часа',
          'completionRate': 98.5,
        },
      ),

      // Фотографы
      SpecialistEnhanced(
        id: 'specialist_2',
        name: 'Мария Иванова',
        specialization: 'Фотограф',
        city: 'Москва',
        region: 'Россия',
        avatarUrl:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
        bio:
            'Свадебный и портретный фотограф. Снимаю в стиле репортаж и постановка.',
        rating: 4.8,
        totalOrders: 89,
        successfulOrders: 87,
        categories: ['Фотографы'],
        languages: ['Русский'],
        pricing: {
          'свадебная_съемка': 80000.0,
          'портретная_съемка': 15000.0,
          'корпоративная_съемка': 30000.0,
        },
        availableDates: ['2024-11-20', '2024-11-21', '2024-11-22'],
        imageUrls: [
          'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=400&h=300&fit=crop',
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=400&h=300&fit=crop',
        ],
        isVerified: true,
        isTopWeek: false,
        isNewcomer: false,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        lastActive: DateTime.now().subtract(const Duration(hours: 1)),
        location: {
          'latitude': 55.7558,
          'longitude': 37.6176,
          'address': 'Москва, Арбат',
        },
        socialLinks: {
          'instagram': '@maria_photo',
          'telegram': '@maria_photo',
        },
        skills: ['Свадебная фотография', 'Портретная съемка', 'Обработка'],
        experience: '5 лет',
        education: 'МГУ, факультет журналистики',
        reviews: [],
        stats: {
          'responseTime': '1 час',
          'completionRate': 97.8,
        },
      ),

      // Кейтеринг
      SpecialistEnhanced(
        id: 'specialist_3',
        name: 'Дмитрий Козлов',
        specialization: 'Кейтеринг',
        city: 'Санкт-Петербург',
        region: 'Россия',
        avatarUrl:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        bio:
            'Профессиональный кейтеринг для любых мероприятий. Европейская и азиатская кухня.',
        rating: 4.7,
        totalOrders: 67,
        successfulOrders: 65,
        categories: ['Кейтеринг'],
        languages: ['Русский', 'Английский'],
        pricing: {
          'фуршет': 1500.0,
          'банкет': 2000.0,
          'кофе_брейк': 800.0,
        },
        availableDates: ['2024-11-18', '2024-11-19', '2024-11-20'],
        imageUrls: [
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=300&fit=crop',
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop',
        ],
        isVerified: true,
        isTopWeek: false,
        isNewcomer: false,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        lastActive: DateTime.now().subtract(const Duration(hours: 3)),
        location: {
          'latitude': 59.9311,
          'longitude': 30.3609,
          'address': 'Санкт-Петербург, Невский проспект',
        },
        socialLinks: {
          'instagram': '@dmitry_catering',
          'telegram': '@dmitry_catering',
        },
        skills: ['Европейская кухня', 'Азиатская кухня', 'Вегетарианское меню'],
        experience: '7 лет',
        education: 'Кулинарная школа Le Cordon Bleu',
        reviews: [],
        stats: {
          'responseTime': '3 часа',
          'completionRate': 97.0,
        },
      ),

      // Декор
      SpecialistEnhanced(
        id: 'specialist_4',
        name: 'Елена Соколова',
        specialization: 'Декор и оформление',
        city: 'Москва',
        region: 'Россия',
        avatarUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        bio:
            'Дизайнер интерьеров и декоратор. Создаю уникальные пространства для ваших мероприятий.',
        rating: 4.9,
        totalOrders: 45,
        successfulOrders: 44,
        categories: ['Декор'],
        languages: ['Русский', 'Французский'],
        pricing: {
          'свадебное_оформление': 120000.0,
          'корпоративное_оформление': 80000.0,
          'детский_праздник': 40000.0,
        },
        availableDates: ['2024-11-25', '2024-11-26', '2024-11-27'],
        imageUrls: [
          'https://images.unsplash.com/photo-1519167758481-83f1426b3a7e?w=400&h=300&fit=crop',
          'https://images.unsplash.com/photo-1464366400600-7168b8af9bc8?w=400&h=300&fit=crop',
        ],
        isVerified: true,
        isTopWeek: true,
        isNewcomer: false,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
        location: {
          'latitude': 55.7558,
          'longitude': 37.6176,
          'address': 'Москва, Тверская',
        },
        socialLinks: {
          'instagram': '@elena_decor',
          'telegram': '@elena_decor',
        },
        skills: ['Цветочный дизайн', 'Световое оформление', '3D визуализация'],
        experience: '8 лет',
        education: 'МАРХИ, факультет дизайна',
        reviews: [],
        stats: {
          'responseTime': '1 час',
          'completionRate': 97.8,
        },
      ),

      // Музыканты
      SpecialistEnhanced(
        id: 'specialist_5',
        name: 'Андрей Волков',
        specialization: 'DJ и музыкант',
        city: 'Москва',
        region: 'Россия',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        bio:
            'DJ с 15-летним опытом. Играю на свадьбах, корпоративах, клубах. Современная и ретро музыка.',
        rating: 4.6,
        totalOrders: 234,
        successfulOrders: 228,
        categories: ['Музыка'],
        languages: ['Русский', 'Английский'],
        pricing: {
          'свадьба': 35000.0,
          'корпоратив': 30000.0,
          'клуб': 20000.0,
        },
        availableDates: ['2024-11-12', '2024-11-13', '2024-11-14'],
        imageUrls: [
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=300&fit=crop',
          'https://images.unsplash.com/photo-1571266028243-d220c8b0a0a0?w=400&h=300&fit=crop',
        ],
        isVerified: true,
        isTopWeek: false,
        isNewcomer: false,
        createdAt: DateTime.now().subtract(const Duration(days: 500)),
        lastActive: DateTime.now().subtract(const Duration(hours: 6)),
        location: {
          'latitude': 55.7558,
          'longitude': 37.6176,
          'address': 'Москва, Сокольники',
        },
        socialLinks: {
          'instagram': '@andrey_dj',
          'telegram': '@andrey_dj',
        },
        skills: ['DJ', 'Световое шоу', 'Звуковое оборудование'],
        experience: '15 лет',
        education: 'МГУКИ, факультет музыкального искусства',
        reviews: [],
        stats: {
          'responseTime': '4 часа',
          'completionRate': 97.4,
        },
      ),

      // Новичок
      SpecialistEnhanced(
        id: 'specialist_6',
        name: 'Ольга Новикова',
        specialization: 'Визажист',
        city: 'Москва',
        region: 'Россия',
        avatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
        bio:
            'Молодой визажист с креативным подходом. Специализируюсь на свадебном и вечернем макияже.',
        rating: 4.5,
        totalOrders: 12,
        successfulOrders: 11,
        categories: ['Красота'],
        languages: ['Русский'],
        pricing: {
          'свадебный_макияж': 8000.0,
          'вечерний_макияж': 5000.0,
          'дневной_макияж': 3000.0,
        },
        availableDates: ['2024-11-10', '2024-11-11', '2024-11-12'],
        imageUrls: [
          'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=300&fit=crop',
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&h=300&fit=crop',
        ],
        isVerified: false,
        isTopWeek: false,
        isNewcomer: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActive: DateTime.now().subtract(const Duration(hours: 12)),
        location: {
          'latitude': 55.7558,
          'longitude': 37.6176,
          'address': 'Москва, Чистые пруды',
        },
        socialLinks: {
          'instagram': '@olga_makeup',
          'telegram': '@olga_makeup',
        },
        skills: ['Свадебный макияж', 'Вечерний макияж', 'Креативный макияж'],
        experience: '1 год',
        education: 'Школа визажа Make Up For Ever',
        reviews: [],
        stats: {
          'responseTime': '2 часа',
          'completionRate': 91.7,
        },
      ),
    ];
  }

  /// Очистить тестовые данные
  static Future<void> clearTestData() async {
    try {
      final batch = _firestore.batch();
      final specialists = await _firestore.collection('specialists').get();

      for (final doc in specialists.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Test data cleared successfully');
    } catch (e) {
      print('❌ Error clearing test data: $e');
    }
  }
}
