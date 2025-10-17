import '../models/photo_studio.dart';
import '../services/photo_studio_service.dart';

class TestPhotoStudioData {
  static final PhotoStudioService _photoStudioService = PhotoStudioService();

  /// Создать тестовые данные для фотостудий
  static Future<void> createTestPhotoStudios() async {
    try {
      final testPhotoStudios = [
        const CreatePhotoStudio(
          name: 'Студия "Свет и Тень"',
          description:
              'Профессиональная фотостудия с современным оборудованием. Идеально подходит для портретной съемки, семейных фотосессий и коммерческих проектов.',
          address: 'ул. Тверская, 15, Москва',
          phone: '+7 (495) 123-45-67',
          email: 'info@svetiten.ru',
          ownerId: 'owner_1',
          avatarUrl: 'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=800',
          coverImageUrl: 'https://images.unsplash.com/photo-1554048612-b6a482b5b2e8?w=800',
          images: [
            'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=800',
            'https://images.unsplash.com/photo-1554048612-b6a482b5b2e8?w=800',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
          ],
          amenities: [
            'Профессиональное освещение',
            'Гримерная',
            'Wi-Fi',
            'Парковка',
          ],
          pricing: {
            'hourlyRate': 2500.0,
            'dailyRate': 15000.0,
            'packages': {
              'Портретная съемка': 2500,
              'Семейная фотосессия': 3000,
              'Коммерческая съемка': 4000,
            },
          },
          workingHours: {
            'monday': {'open': '09:00', 'close': '21:00'},
            'tuesday': {'open': '09:00', 'close': '21:00'},
            'wednesday': {'open': '09:00', 'close': '21:00'},
            'thursday': {'open': '09:00', 'close': '21:00'},
            'friday': {'open': '09:00', 'close': '21:00'},
            'saturday': {'open': '10:00', 'close': '20:00'},
            'sunday': {'open': '10:00', 'close': '18:00'},
          },
          location: {
            'latitude': 55.7558,
            'longitude': 37.6176,
            'city': 'Москва',
          },
        ),
        const CreatePhotoStudio(
          name: 'Art Studio Pro',
          description:
              'Креативная студия для художественной фотографии. Уникальные декорации и профессиональное освещение для создания неповторимых образов.',
          address: 'пр. Мира, 42, Москва',
          phone: '+7 (495) 234-56-78',
          email: 'hello@artstudiopro.ru',
          ownerId: 'owner_2',
          avatarUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
          coverImageUrl: 'https://images.unsplash.com/photo-1554048612-b6a482b5b2e8?w=800',
          images: [
            'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
            'https://images.unsplash.com/photo-1554048612-b6a482b5b2e8?w=800',
          ],
          amenities: [
            'Художественное освещение',
            'Декорации',
            'Гримерная',
            'Wi-Fi',
          ],
          pricing: {
            'hourlyRate': 3000.0,
            'dailyRate': 18000.0,
            'packages': {
              'Художественная съемка': 3000,
              'Портретная съемка': 2500,
              'Фэшн съемка': 3500,
            },
          },
          workingHours: {
            'monday': {'open': '10:00', 'close': '22:00'},
            'tuesday': {'open': '10:00', 'close': '22:00'},
            'wednesday': {'open': '10:00', 'close': '22:00'},
            'thursday': {'open': '10:00', 'close': '22:00'},
            'friday': {'open': '10:00', 'close': '22:00'},
            'saturday': {'open': '11:00', 'close': '21:00'},
            'sunday': {'open': '11:00', 'close': '19:00'},
          },
          location: {
            'latitude': 55.7804,
            'longitude': 37.6392,
            'city': 'Москва',
          },
        ),
        const CreatePhotoStudio(
          name: 'Студия "Момент"',
          description:
              'Уютная студия для семейных фотосессий и детских съемок. Доброжелательная атмосфера и опытные фотографы помогут создать теплые воспоминания.',
          address: 'ул. Арбат, 8, Москва',
          phone: '+7 (495) 345-67-89',
          email: 'contact@moment-studio.ru',
          ownerId: 'owner_3',
          avatarUrl: 'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=800',
          coverImageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
          images: [
            'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=800',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
            'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
            'https://images.unsplash.com/photo-1554048612-b6a482b5b2e8?w=800',
          ],
          amenities: [
            'Мягкое освещение',
            'Детская зона',
            'Гримерная',
            'Wi-Fi',
            'Парковка',
          ],
          pricing: {
            'hourlyRate': 1800.0,
            'dailyRate': 12000.0,
            'packages': {
              'Семейная фотосессия': 1800,
              'Детская съемка': 1500,
              'Портретная съемка': 2000,
            },
          },
          workingHours: {
            'monday': {'open': '09:00', 'close': '20:00'},
            'tuesday': {'open': '09:00', 'close': '20:00'},
            'wednesday': {'open': '09:00', 'close': '20:00'},
            'thursday': {'open': '09:00', 'close': '20:00'},
            'friday': {'open': '09:00', 'close': '20:00'},
            'saturday': {'open': '10:00', 'close': '19:00'},
            'sunday': {'open': '10:00', 'close': '18:00'},
          },
          location: {
            'latitude': 55.7522,
            'longitude': 37.5911,
            'city': 'Москва',
          },
        ),
        const CreatePhotoStudio(
          name: 'Luxury Photo Studio',
          description:
              'Премиум студия для VIP-съемок и коммерческих проектов. Эксклюзивные локации, профессиональная команда и индивидуальный подход к каждому клиенту.',
          address: 'Красная площадь, 1, Москва',
          phone: '+7 (495) 456-78-90',
          email: 'vip@luxuryphoto.ru',
          ownerId: 'owner_4',
          avatarUrl: 'https://images.unsplash.com/photo-1554048612-b6a482b5b2e8?w=800',
          coverImageUrl: 'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=800',
          images: [
            'https://images.unsplash.com/photo-1554048612-b6a482b5b2e8?w=800',
            'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=800',
          ],
          amenities: [
            'VIP зона',
            'Профессиональное освещение',
            'Гримерная',
            'Wi-Fi',
            'Парковка',
            'Консьерж',
          ],
          pricing: {
            'hourlyRate': 5000.0,
            'dailyRate': 30000.0,
            'packages': {
              'VIP съемка': 5000,
              'Коммерческая съемка': 4000,
              'Портретная съемка': 3000,
            },
          },
          workingHours: {
            'monday': {'open': '08:00', 'close': '23:00'},
            'tuesday': {'open': '08:00', 'close': '23:00'},
            'wednesday': {'open': '08:00', 'close': '23:00'},
            'thursday': {'open': '08:00', 'close': '23:00'},
            'friday': {'open': '08:00', 'close': '23:00'},
            'saturday': {'open': '09:00', 'close': '22:00'},
            'sunday': {'open': '09:00', 'close': '20:00'},
          },
          location: {
            'latitude': 55.7539,
            'longitude': 37.6208,
            'city': 'Москва',
          },
        ),
        const CreatePhotoStudio(
          name: 'Студия "Радуга"',
          description:
              'Яркая и современная студия для молодежных фотосессий и творческих проектов. Разнообразные фоны и реквизит для создания уникальных кадров.',
          address: 'ул. Новый Арбат, 25, Москва',
          phone: '+7 (495) 567-89-01',
          email: 'info@raduga-studio.ru',
          ownerId: 'owner_5',
          avatarUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
          coverImageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
          images: [
            'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
            'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=800',
          ],
          amenities: ['Цветное освещение', 'Реквизит', 'Гримерная', 'Wi-Fi'],
          pricing: {
            'hourlyRate': 2200.0,
            'dailyRate': 14000.0,
            'packages': {
              'Молодежная съемка': 2200,
              'Творческая съемка': 2500,
              'Портретная съемка': 2000,
            },
          },
          workingHours: {
            'monday': {'open': '10:00', 'close': '21:00'},
            'tuesday': {'open': '10:00', 'close': '21:00'},
            'wednesday': {'open': '10:00', 'close': '21:00'},
            'thursday': {'open': '10:00', 'close': '21:00'},
            'friday': {'open': '10:00', 'close': '21:00'},
            'saturday': {'open': '11:00', 'close': '20:00'},
            'sunday': {'open': '11:00', 'close': '19:00'},
          },
          location: {
            'latitude': 55.7522,
            'longitude': 37.5911,
            'city': 'Москва',
          },
        ),
        const CreatePhotoStudio(
          name: 'Black & White Studio',
          description:
              'Минималистичная студия для черно-белой фотографии. Классический подход и внимание к деталям для создания timeless образов.',
          address: 'ул. Петровка, 12, Москва',
          phone: '+7 (495) 678-90-12',
          email: 'studio@blackwhite.ru',
          ownerId: 'owner_6',
          avatarUrl: 'https://images.unsplash.com/photo-1554048612-b6a482b5b2e8?w=800',
          coverImageUrl: 'https://images.unsplash.com/photo-1554048612-b6a482b5b2e8?w=800',
          images: [
            'https://images.unsplash.com/photo-1554048612-b6a482b5b2e8?w=800',
          ],
          amenities: ['Классическое освещение', 'Гримерная', 'Wi-Fi'],
          pricing: {
            'hourlyRate': 2800.0,
            'dailyRate': 16000.0,
            'packages': {
              'Черно-белая съемка': 2800,
              'Портретная съемка': 2500,
              'Арт съемка': 3000,
            },
          },
          workingHours: {
            'monday': {'open': '09:00', 'close': '20:00'},
            'tuesday': {'open': '09:00', 'close': '20:00'},
            'wednesday': {'open': '09:00', 'close': '20:00'},
            'thursday': {'open': '09:00', 'close': '20:00'},
            'friday': {'open': '09:00', 'close': '20:00'},
            'saturday': {'open': '10:00', 'close': '19:00'},
            'sunday': {'open': '10:00', 'close': '18:00'},
          },
          location: {
            'latitude': 55.7558,
            'longitude': 37.6176,
            'city': 'Москва',
          },
        ),
      ];

      // Добавляем каждую фотостудию
      for (final photoStudio in testPhotoStudios) {
        await _photoStudioService.createPhotoStudio(photoStudio);
        print('Добавлена фотостудия: ${photoStudio.name}');
      }

      print('✅ Создано ${testPhotoStudios.length} тестовых фотостудий');
    } catch (e) {
      print('❌ Ошибка создания тестовых фотостудий: $e');
    }
  }

  /// Очистить все тестовые данные
  static Future<void> clearTestPhotoStudios() async {
    try {
      final photoStudios = await _photoStudioService.getPhotoStudios();

      for (final photoStudio in photoStudios) {
        await _photoStudioService.deletePhotoStudio(photoStudio.id);
        print('Удалена фотостудия: ${photoStudio.name}');
      }

      print('✅ Очищены все тестовые фотостудии');
    } catch (e) {
      print('❌ Ошибка очистки тестовых фотостудий: $e');
    }
  }

  /// Получить количество тестовых фотостудий
  static Future<int> getTestPhotoStudiosCount() async {
    try {
      final photoStudios = await _photoStudioService.getPhotoStudios();
      return photoStudios.length;
    } catch (e) {
      print('❌ Ошибка получения количества фотостудий: $e');
      return 0;
    }
  }
}
