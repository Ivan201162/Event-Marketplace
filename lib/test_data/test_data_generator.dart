import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking.dart';
import '../models/event_idea.dart';
import '../models/review.dart';
import '../models/specialist.dart';
import '../models/user.dart';

/// Генератор тестовых данных для Event Marketplace
class TestDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Счетчики для прогресса
  int _generatedSpecialists = 0;
  int _generatedCustomers = 0;
  int _generatedBookings = 0;
  int _generatedReviews = 0;
  int _generatedIdeas = 0;
  final int _generatedChats = 0;

  /// Русские города для генерации данных
  static const List<String> russianCities = [
    'Москва',
    'Санкт-Петербург',
    'Новосибирск',
    'Екатеринбург',
    'Казань',
    'Нижний Новгород',
    'Челябинск',
    'Омск',
    'Самара',
    'Ростов-на-Дону',
    'Уфа',
    'Красноярск',
    'Воронеж',
    'Пермь',
    'Волгоград',
    'Краснодар',
    'Саратов',
    'Тюмень',
    'Тольятти',
    'Ижевск',
    'Барнаул',
    'Ульяновск',
    'Иркутск',
    'Хабаровск',
    'Ярославль',
    'Владивосток',
    'Махачкала',
    'Томск',
    'Оренбург',
    'Кемерово',
    'Новокузнецк',
    'Рязань',
    'Набережные Челны',
    'Астрахань',
    'Пенза',
    'Липецк',
    'Киров',
    'Чебоксары',
    'Тула',
    'Калининград',
    'Брянск',
    'Курск',
    'Иваново',
    'Магнитогорск',
    'Тверь',
    'Ставрополь',
    'Белгород',
    'Сочи',
    'Нижний Тагил',
    'Архангельск',
    'Владимир',
    'Калуга',
    'Чита',
    'Смоленск',
    'Волжский',
    'Череповец',
    'Курган',
    'Орел',
    'Вологда',
    'Саранск',
    'Тамбов',
    'Стерлитамак',
    'Грозный',
    'Якутск',
    'Кострома',
    'Комсомольск-на-Амуре',
    'Петрозаводск',
    'Таганрог',
    'Нижневартовск',
    'Йошкар-Ола',
    'Братск',
    'Новороссийск',
    'Дзержинск',
    'Шахты',
    'Орск',
    'Ангарск',
    'Сыктывкар',
    'Нижнекамск',
    'Старый Оскол',
    'Бийск',
    'Прокопьевск',
    'Рыбинск',
    'Балково',
    'Северодвинск',
    'Армавир',
    'Подольск',
    'Королев',
    'Южно-Сахалинск',
    'Петропавловск-Камчатский',
    'Мурманск',
    'Химки',
    'Мытищи',
    'Люберцы',
    'Красногорск',
    'Электросталь',
    'Коломна',
    'Одинцово',
    'Домодедово',
    'Серпухов',
    'Щелково',
    'Орехово-Зуево',
    'Новомосковск',
    'Златоуст',
    'Камышин',
    'Соликамск',
    'Великий Новгород',
    'Псков',
    'Благовещенск',
    'Энгельс',
    'Мичуринск',
    'Первоуральск',
    'Рубцовск',
    'Железнодорожный',
    'Лыткарино',
    'Жуковский',
    'Ковров',
    'Елец',
    'Ачинск',
    'Евпатория',
    'Кисловодск',
    'Пятигорск',
    'Минеральные Воды',
    'Ессентуки',
    'Железноводск',
  ];

  /// Мужские имена
  static const List<String> maleNames = [
    'Александр',
    'Дмитрий',
    'Максим',
    'Сергей',
    'Андрей',
    'Алексей',
    'Артем',
    'Илья',
    'Кирилл',
    'Михаил',
    'Никита',
    'Матвей',
    'Роман',
    'Егор',
    'Арсений',
    'Иван',
    'Денис',
    'Евгений',
    'Данил',
    'Тимур',
    'Владислав',
    'Игорь',
    'Владимир',
    'Павел',
    'Руслан',
    'Марк',
    'Константин',
    'Тимофей',
    'Николай',
    'Степан',
    'Федор',
    'Георгий',
    'Лев',
    'Виктор',
    'Антон',
    'Глеб',
    'Семен',
    'Ярослав',
    'Захар',
    'Богдан',
    'Савелий',
    'Давид',
  ];

  /// Женские имена
  static const List<String> femaleNames = [
    'Анна',
    'Мария',
    'Елена',
    'Дарья',
    'Алина',
    'Ирина',
    'Екатерина',
    'Арина',
    'Полина',
    'Ольга',
    'Юлия',
    'Татьяна',
    'Наталья',
    'Виктория',
    'Елизавета',
    'Анастасия',
    'Валерия',
    'Варвара',
    'Александра',
    'Вероника',
    'София',
    'Кристина',
    'Алиса',
    'Ксения',
    'Милана',
    'Диана',
    'Маргарита',
    'Карина',
    'Стефания',
    'Эмилия',
    'Кира',
    'Камила',
    'Ева',
    'Амелия',
    'Ульяна',
    'Лилия',
    'Злата',
    'Мирослава',
    'Агата',
    'Василиса',
    'Нина',
    'Светлана',
    'Людмила',
    'Любовь',
    'Галина',
    'Тамара',
  ];

  /// Фамилии
  static const List<String> lastNames = [
    'Иванов',
    'Петров',
    'Сидоров',
    'Смирнов',
    'Кузнецов',
    'Попов',
    'Лебедев',
    'Козлов',
    'Новиков',
    'Морозов',
    'Соколов',
    'Волков',
    'Федоров',
    'Михайлов',
    'Николаев',
    'Захаров',
    'Степанов',
    'Сергеев',
    'Владимиров',
    'Фролов',
    'Александров',
    'Дмитриев',
    'Королев',
    'Гусев',
    'Киселев',
    'Ильин',
    'Максимов',
    'Поляков',
    'Сорокин',
    'Виноградов',
    'Ковалев',
    'Белов',
    'Медведев',
    'Антонов',
    'Тарасов',
    'Жуков',
    'Баранов',
    'Филиппов',
    'Комаров',
    'Давыдов',
    'Беляев',
    'Герасимов',
    'Богданов',
    'Осипов',
    'Сидоров',
    'Матвеев',
    'Титов',
    'Марков',
    'Миронов',
    'Крылов',
  ];

  /// Генерация случайного имени
  String _generateRandomName({bool isMale = true}) {
    final firstName = isMale
        ? maleNames[_random.nextInt(maleNames.length)]
        : femaleNames[_random.nextInt(femaleNames.length)];
    final lastName = lastNames[_random.nextInt(lastNames.length)];

    // Для женщин добавляем окончание -а к фамилии
    final adjustedLastName = isMale ? lastName : '$lastNameа';

    return '$firstName $adjustedLastName';
  }

  /// Генерация случайного города
  String _generateRandomCity() => russianCities[_random.nextInt(russianCities.length)];

  /// Генерация URL фото-заглушки
  String _generatePhotoUrl() {
    final id = _random.nextInt(1000) + 1;
    return 'https://picsum.photos/400/400?random=$id';
  }

  /// Генерация специалистов
  Future<List<Specialist>> generateSpecialists({int count = 2000}) async {
    print('🚀 Генерация $count специалистов...');

    final specialists = <Specialist>[];
    const categories = SpecialistCategory.values;

    for (var i = 0; i < count; i++) {
      final category = categories[_random.nextInt(categories.length)];
      final isMale = _random.nextBool();
      final name = _generateRandomName(isMale: isMale);
      final city = _generateRandomCity();
      final experience = _random.nextInt(15) + 1;
      final rating = 4.0 + _random.nextDouble();
      final reviewCount = _random.nextInt(50) + 1;

      final specialist = Specialist(
        id: 'specialist_$i',
        userId: 'user_specialist_$i',
        name: name,
        description: _generateSpecialistDescription(category),
        category: category,
        categories: [category],
        subcategories: _generateSubcategories(category),
        experienceLevel: _getExperienceLevel(experience),
        yearsOfExperience: experience,
        hourlyRate: _generateHourlyRate(category, experience),
        location: city,
        serviceAreas: [city],
        equipment: _generateEquipment(category),
        services: _generateServices(category),
        portfolioImages: _generatePortfolioImages(),
        workingHours: _generateWorkingHours(),
        isAvailable: _random.nextBool(),
        isVerified: _random.nextDouble() > 0.3,
        rating: rating,
        reviewCount: reviewCount,
        createdAt: _generateRandomDate(),
        updatedAt: DateTime.now(),
        profileImageUrl: _generatePhotoUrl(),
        phone: _generatePhoneNumber(),
        email: _generateEmail(name),
      );

      specialists.add(specialist);
      _generatedSpecialists++;

      if (i % 100 == 0) {
        print('✅ Сгенерировано специалистов: ${i + 1}/$count');
      }
    }

    print('✅ Генерация специалистов завершена: $count');
    return specialists;
  }

  /// Генерация заказчиков
  Future<List<AppUser>> generateCustomers({int count = 500}) async {
    print('🚀 Генерация $count заказчиков...');

    final customers = <AppUser>[];

    for (var i = 0; i < count; i++) {
      final isMale = _random.nextBool();
      final name = _generateRandomName(isMale: isMale);

      final customer = AppUser(
        id: 'customer_$i',
        email: _generateEmail(name),
        displayName: name,
        photoURL: _generatePhotoUrl(),
        role: UserRole.customer,
        createdAt: _generateRandomDate(),
        lastLoginAt: _generateRecentDate(),
        maritalStatus: _generateMaritalStatus(),
      );

      customers.add(customer);
      _generatedCustomers++;

      if (i % 50 == 0) {
        print('✅ Сгенерировано заказчиков: ${i + 1}/$count');
      }
    }

    print('✅ Генерация заказчиков завершена: $count');
    return customers;
  }

  /// Генерация бронирований
  Future<List<Booking>> generateBookings(
    List<AppUser> customers,
    List<Specialist> specialists, {
    int maxBookingsPerPair = 3,
  }) async {
    print('🚀 Генерация бронирований...');

    final bookings = <Booking>[];
    var bookingId = 0;

    for (final customer in customers) {
      // Каждый заказчик может иметь бронирования с несколькими специалистами
      final specialistCount = _random.nextInt(5) + 1;
      final selectedSpecialists = specialists..shuffle();

      for (var i = 0; i < specialistCount && i < selectedSpecialists.length; i++) {
        final specialist = selectedSpecialists[i];
        final bookingCount = _random.nextInt(maxBookingsPerPair) + 1;

        for (var j = 0; j < bookingCount; j++) {
          final eventDate = _generateFutureDate();
          final totalPrice = _generateBookingPrice(specialist.hourlyRate);

          final booking = Booking(
            id: 'booking_${bookingId++}',
            eventId: 'event_$bookingId',
            eventTitle: _generateEventTitle(),
            userId: customer.id,
            userName: customer.displayName ?? 'Пользователь',
            userEmail: customer.email,
            status: _generateBookingStatus(),
            bookingDate: DateTime.now(),
            eventDate: eventDate,
            participantsCount: _random.nextInt(50) + 10,
            totalPrice: totalPrice,
            notes: _generateBookingNotes(),
            createdAt: _generateRandomDate(),
            updatedAt: DateTime.now(),
            customerId: customer.id,
            specialistId: specialist.id,
            specialistName: specialist.name,
            prepayment: totalPrice * 0.3, // 30% предоплата
            eventLocation: _generateRandomCity(),
            duration: Duration(hours: _random.nextInt(8) + 2), // 2-10 часов
          );

          bookings.add(booking);
          _generatedBookings++;
        }
      }

      if (_generatedBookings % 100 == 0) {
        print('✅ Сгенерировано бронирований: $_generatedBookings');
      }
    }

    print('✅ Генерация бронирований завершена: ${bookings.length}');
    return bookings;
  }

  /// Генерация отзывов
  Future<List<Review>> generateReviews(
    List<Booking> bookings,
    List<AppUser> customers,
    List<Specialist> specialists,
  ) async {
    print('🚀 Генерация отзывов...');

    final reviews = <Review>[];

    for (final booking in bookings) {
      // Не все бронирования имеют отзывы
      if (_random.nextDouble() > 0.7) continue;

      final customer = customers.firstWhere((c) => c.id == booking.customerId);
      final specialist = specialists.firstWhere((s) => s.id == booking.specialistId);

      final rating = _generateReviewRating();

      final review = Review(
        id: 'review_${reviews.length}',
        bookingId: booking.id,
        reviewerId: customer.id,
        reviewerName: customer.displayName ?? 'Пользователь',
        reviewerAvatar: customer.photoURL,
        targetId: specialist.id,
        type: ReviewType.specialist,
        rating: rating,
        title: _generateReviewTitle(rating),
        content: _generateReviewContent(rating, specialist.category),
        tags: _generateReviewTags(rating),
        status: ReviewStatus.approved,
        createdAt: _generateRandomDate(),
        isVerified: _random.nextDouble() > 0.5,
        helpfulCount: _random.nextInt(20),
        specialistId: specialist.id,
      );

      reviews.add(review);
      _generatedReviews++;

      if (_generatedReviews % 100 == 0) {
        print('✅ Сгенерировано отзывов: $_generatedReviews');
      }
    }

    print('✅ Генерация отзывов завершена: ${reviews.length}');
    return reviews;
  }

  /// Генерация идей для мероприятий
  Future<List<EventIdea>> generateEventIdeas({int count = 1000}) async {
    print('🚀 Генерация $count идей для мероприятий...');

    final ideas = <EventIdea>[];
    final categories = EventIdeaCategories.categories;
    final eventTypes = EventIdeaCategories.eventTypes;
    final budgets = EventIdeaCategories.budgets;
    final seasons = EventIdeaCategories.seasons;
    final venues = EventIdeaCategories.venues;

    for (var i = 0; i < count; i++) {
      final category = categories[_random.nextInt(categories.length)];
      final eventType = eventTypes[_random.nextInt(eventTypes.length)];

      final idea = EventIdea(
        id: 'idea_$i',
        title: _generateIdeaTitle(category),
        description: _generateIdeaDescription(category),
        category: category,
        imageUrls: _generateIdeaImages(),
        videoUrls: [],
        authorId: 'admin',
        authorName: 'Event Marketplace',
        tags: _generateIdeaTags(category),
        likesCount: _random.nextInt(1000),
        savesCount: _random.nextInt(500),
        eventType: eventType,
        budget: budgets[_random.nextInt(budgets.length)],
        season: seasons[_random.nextInt(seasons.length)],
        venue: venues[_random.nextInt(venues.length)],
      );

      ideas.add(idea);
      _generatedIdeas++;

      if (i % 100 == 0) {
        print('✅ Сгенерировано идей: ${i + 1}/$count');
      }
    }

    print('✅ Генерация идей завершена: $count');
    return ideas;
  }

  /// Массовая загрузка в Firestore
  Future<void> populateFirestore() async {
    print('🚀 Начинаем массовую загрузку данных в Firestore...');

    try {
      // 1. Генерируем данные
      final specialists = await generateSpecialists();
      final customers = await generateCustomers();
      final bookings = await generateBookings(customers, specialists);
      final reviews = await generateReviews(bookings, customers, specialists);
      final ideas = await generateEventIdeas();

      // 2. Загружаем в Firestore батчами
      await uploadSpecialists(specialists);
      await uploadCustomers(customers);
      await uploadBookings(bookings);
      await uploadReviews(reviews);
      await uploadIdeas(ideas);

      print('✅ Массовая загрузка завершена успешно!');
    } catch (e) {
      print('❌ Ошибка при загрузке данных: $e');
      rethrow;
    }
  }

  /// Проверка загруженных данных
  Future<void> verifyTestData() async {
    print('🔍 Проверка загруженных данных...');

    try {
      // Проверяем количество документов в каждой коллекции
      final specialistsCount = await _getCollectionCount('specialists');
      final customersCount = await _getCollectionCount('users');
      final bookingsCount = await _getCollectionCount('bookings');
      final reviewsCount = await _getCollectionCount('reviews');
      final ideasCount = await _getCollectionCount('event_ideas');

      print('\n📊 СТАТИСТИКА ЗАГРУЖЕННЫХ ДАННЫХ:');
      print('👥 Специалисты: $specialistsCount');
      print('👤 Заказчики: $customersCount');
      print('📅 Бронирования: $bookingsCount');
      print('⭐ Отзывы: $reviewsCount');
      print('💡 Идеи: $ideasCount');

      // Выводим примеры данных
      await _printSampleData();
    } catch (e) {
      print('❌ Ошибка при проверке данных: $e');
    }
  }

  // Вспомогательные методы для генерации данных

  String _generateSpecialistDescription(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.photographer:
        return 'Профессиональный фотограф с многолетним опытом. Специализируюсь на свадебной, портретной и событийной фотографии.';
      case SpecialistCategory.videographer:
        return 'Создаю качественные видеоролики для различных мероприятий. Профессиональное оборудование и творческий подход.';
      case SpecialistCategory.dj:
        return 'Опытный диджей с большой музыкальной коллекцией. Создам незабываемую атмосферу на вашем мероприятии.';
      case SpecialistCategory.host:
        return 'Профессиональный ведущий мероприятий. Харизматичный, опытный, умею работать с любой аудиторией.';
      case SpecialistCategory.florist:
        return 'Создаю уникальные флористические композиции для любых торжеств. Свежие цветы, креативные решения.';
      default:
        return 'Профессиональный специалист в сфере организации мероприятий с большим опытом работы.';
    }
  }

  List<String> _generateSubcategories(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.photographer:
        return ['Свадебная фотография', 'Портретная съемка', 'Событийная фотография'];
      case SpecialistCategory.videographer:
        return ['Свадебное видео', 'Корпоративные ролики', 'Музыкальные клипы'];
      case SpecialistCategory.dj:
        return ['Свадебный диджей', 'Корпоративные мероприятия', 'Клубная музыка'];
      case SpecialistCategory.host:
        return ['Свадебный ведущий', 'Корпоративные мероприятия', 'Детские праздники'];
      case SpecialistCategory.florist:
        return ['Свадебная флористика', 'Букеты', 'Декор мероприятий'];
      default:
        return ['Основные услуги', 'Дополнительные услуги'];
    }
  }

  ExperienceLevel _getExperienceLevel(int years) {
    if (years >= 10) return ExperienceLevel.expert;
    if (years >= 5) return ExperienceLevel.advanced;
    if (years >= 2) return ExperienceLevel.intermediate;
    return ExperienceLevel.beginner;
  }

  double _generateHourlyRate(SpecialistCategory category, int experience) {
    final baseRate = _getCategoryBaseRate(category);
    final experienceMultiplier = 1.0 + (experience * 0.1);
    final variation = 0.8 + (_random.nextDouble() * 0.4); // ±20% вариация
    return (baseRate * experienceMultiplier * variation).roundToDouble();
  }

  double _getCategoryBaseRate(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.photographer:
      case SpecialistCategory.videographer:
        return 5000;
      case SpecialistCategory.dj:
      case SpecialistCategory.host:
        return 3000;
      case SpecialistCategory.florist:
      case SpecialistCategory.decorator:
        return 2500;
      case SpecialistCategory.musician:
        return 4000;
      case SpecialistCategory.caterer:
        return 1500;
      default:
        return 2000;
    }
  }

  List<String> _generateEquipment(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.photographer:
        return ['Профессиональный фотоаппарат', 'Штатив', 'Освещение', 'Объективы'];
      case SpecialistCategory.videographer:
        return ['Видеокамера 4K', 'Стабилизатор', 'Микрофоны', 'Освещение'];
      case SpecialistCategory.dj:
        return ['DJ-контроллер', 'Колонки', 'Микшер', 'Микрофоны'];
      case SpecialistCategory.host:
        return ['Микрофон', 'Костюмы', 'Реквизит'];
      default:
        return ['Профессиональное оборудование'];
    }
  }

  List<String> _generateServices(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.photographer:
        return ['Свадебная съемка', 'Портреты', 'Обработка фото', 'Печать'];
      case SpecialistCategory.videographer:
        return ['Съемка мероприятий', 'Монтаж видео', 'Цветокоррекция'];
      case SpecialistCategory.dj:
        return ['Музыкальное сопровождение', 'Световое шоу', 'Ведение программы'];
      case SpecialistCategory.host:
        return ['Ведение мероприятий', 'Конкурсы', 'Интерактивы'];
      default:
        return ['Основные услуги категории'];
    }
  }

  List<String> _generatePortfolioImages() => List.generate(5, (index) => _generatePhotoUrl());

  Map<String, String> _generateWorkingHours() => {
    'monday': '09:00-18:00',
    'tuesday': '09:00-18:00',
    'wednesday': '09:00-18:00',
    'thursday': '09:00-18:00',
    'friday': '09:00-18:00',
    'saturday': '10:00-16:00',
    'sunday': 'выходной',
  };

  String _generatePhoneNumber() =>
      '+7${_random.nextInt(900) + 100}${_random.nextInt(900) + 100}${_random.nextInt(10000).toString().padLeft(4, '0')}';

  String _generateEmail(String name) {
    final cleanName = name.toLowerCase().replaceAll(' ', '.');
    final domains = ['gmail.com', 'yandex.ru', 'mail.ru', 'ya.ru'];
    final domain = domains[_random.nextInt(domains.length)];
    return '$cleanName@$domain';
  }

  DateTime _generateRandomDate() {
    final now = DateTime.now();
    final daysAgo = _random.nextInt(365);
    return now.subtract(Duration(days: daysAgo));
  }

  DateTime _generateRecentDate() {
    final now = DateTime.now();
    final daysAgo = _random.nextInt(30);
    return now.subtract(Duration(days: daysAgo));
  }

  DateTime _generateFutureDate() {
    final now = DateTime.now();
    final daysAhead = _random.nextInt(180) + 30; // 30-210 дней вперед
    return now.add(Duration(days: daysAhead));
  }

  MaritalStatus _generateMaritalStatus() {
    const statuses = MaritalStatus.values;
    return statuses[_random.nextInt(statuses.length)];
  }

  BookingStatus _generateBookingStatus() {
    final statuses = [BookingStatus.pending, BookingStatus.confirmed, BookingStatus.completed];
    final weights = [0.2, 0.5, 0.3]; // Веса для статусов

    final random = _random.nextDouble();
    var cumulative = 0;

    for (var i = 0; i < statuses.length; i++) {
      cumulative += weights[i];
      if (random <= cumulative) {
        return statuses[i];
      }
    }

    return BookingStatus.confirmed;
  }

  String _generateEventTitle() {
    final titles = [
      'Свадебное торжество',
      'День рождения',
      'Корпоративное мероприятие',
      'Юбилей',
      'Выпускной',
      'Новогодний праздник',
      'Презентация',
      'Конференция',
      'Семинар',
      'Тимбилдинг',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  double _generateBookingPrice(double hourlyRate) {
    final hours = _random.nextInt(8) + 2; // 2-10 часов
    final basePrice = hourlyRate * hours;
    final variation = 0.8 + (_random.nextDouble() * 0.4); // ±20% вариация
    return (basePrice * variation).roundToDouble();
  }

  String _generateBookingNotes() {
    final notes = [
      'Требуется дополнительное освещение',
      'Мероприятие на открытом воздухе',
      'Особые пожелания по музыке',
      'Нужна помощь с организацией',
      'Важное событие, все должно быть идеально',
      'Много гостей, учесть логистику',
      'Тематическое оформление',
      'Детское мероприятие, безопасность важна',
    ];

    if (_random.nextDouble() > 0.3) return '';
    return notes[_random.nextInt(notes.length)];
  }

  int _generateReviewRating() {
    // Генерируем в основном хорошие оценки (4-5)
    final random = _random.nextDouble();
    if (random < 0.6) return 5;
    if (random < 0.85) return 4;
    if (random < 0.95) return 3;
    if (random < 0.99) return 2;
    return 1;
  }

  String _generateReviewTitle(int rating) {
    if (rating >= 4) {
      final titles = [
        'Отличная работа!',
        'Превзошел ожидания',
        'Рекомендую всем',
        'Профессионал своего дела',
        'Очень довольны результатом',
      ];
      return titles[_random.nextInt(titles.length)];
    } else {
      final titles = [
        'Неплохо, но есть замечания',
        'Средний результат',
        'Можно лучше',
        'Есть над чем работать',
      ];
      return titles[_random.nextInt(titles.length)];
    }
  }

  String _generateReviewContent(int rating, SpecialistCategory category) {
    if (rating >= 4) {
      switch (category) {
        case SpecialistCategory.photographer:
          return 'Замечательный фотограф! Отличные кадры, профессиональный подход. Очень довольны качеством фотографий.';
        case SpecialistCategory.videographer:
          return 'Потрясающее видео получилось! Качественная съемка и монтаж. Рекомендуем!';
        case SpecialistCategory.dj:
          return 'Отличный диджей! Музыка была супер, все гости танцевали всю ночь.';
        case SpecialistCategory.host:
          return 'Прекрасный ведущий! Веселая программа, все гости были в восторге.';
        default:
          return 'Очень довольны работой специалиста. Профессиональный подход и отличный результат.';
      }
    } else {
      return 'Работа выполнена, но есть замечания. Можно было бы лучше.';
    }
  }

  List<String> _generateReviewTags(int rating) {
    if (rating >= 4) {
      return ['профессионализм', 'качество', 'рекомендую'];
    } else {
      return ['есть замечания', 'средне'];
    }
  }

  String _generateIdeaTitle(String category) {
    switch (category) {
      case 'Свадьба':
        final titles = [
          'Романтическая свадьба в стиле прованс',
          'Классическая свадьба в ресторане',
          'Выездная церемония на природе',
          'Свадьба в стиле лофт',
          'Морская свадьба',
        ];
        return titles[_random.nextInt(titles.length)];
      case 'День рождения':
        final titles = [
          'Яркий день рождения для взрослых',
          'Детский праздник с аниматорами',
          'Стильная вечеринка в клубе',
          'Домашний уютный праздник',
          'Тематическая вечеринка',
        ];
        return titles[_random.nextInt(titles.length)];
      case 'Корпоратив':
        final titles = [
          'Новогодний корпоратив',
          'День компании на природе',
          'Элегантный банкет',
          'Активный тимбилдинг',
          'Презентация нового продукта',
        ];
        return titles[_random.nextInt(titles.length)];
      default:
        return 'Идея для $category';
    }
  }

  String _generateIdeaDescription(String category) {
    switch (category) {
      case 'Свадьба':
        return 'Создайте незабываемый день с продуманным декором, красивой фотозоной и особенной атмосферой. Каждая деталь важна для создания магии вашего особенного дня.';
      case 'День рождения':
        return 'Яркий и запоминающийся праздник для именинника и гостей. Веселая программа, вкусные угощения и отличное настроение гарантированы.';
      case 'Корпоратив':
        return 'Корпоративное мероприятие, которое сплотит команду и создаст позитивную атмосферу в коллективе. Профессиональная организация и развлекательная программа.';
      default:
        return 'Оригинальная идея для организации незабываемого мероприятия с продуманной программой и особенной атмосферой.';
    }
  }

  List<String> _generateIdeaImages() => List.generate(3, (index) => _generatePhotoUrl());

  List<String> _generateIdeaTags(String category) {
    switch (category) {
      case 'Свадьба':
        return ['свадьба', 'торжество', 'романтика', 'церемония'];
      case 'День рождения':
        return ['день рождения', 'праздник', 'веселье', 'подарки'];
      case 'Корпоратив':
        return ['корпоратив', 'команда', 'работа', 'коллеги'];
      default:
        return ['мероприятие', 'праздник', 'событие'];
    }
  }

  // Методы загрузки в Firestore (публичные для доступа из run_data_generation.dart)

  Future<void> uploadSpecialists(List<Specialist> specialists) async {
    print('📤 Загружаем специалистов в Firestore...');
    await _uploadInBatches('specialists', specialists, (s) => s.toMap());
  }

  Future<void> uploadCustomers(List<AppUser> customers) async {
    print('📤 Загружаем заказчиков в Firestore...');
    await _uploadInBatches('users', customers, (u) => u.toMap());
  }

  Future<void> uploadBookings(List<Booking> bookings) async {
    print('📤 Загружаем бронирования в Firestore...');
    await _uploadInBatches('bookings', bookings, (b) => b.toMap());
  }

  Future<void> uploadReviews(List<Review> reviews) async {
    print('📤 Загружаем отзывы в Firestore...');
    await _uploadInBatches('reviews', reviews, (r) => r.toMap());
  }

  Future<void> uploadIdeas(List<EventIdea> ideas) async {
    print('📤 Загружаем идеи в Firestore...');
    await _uploadInBatches('event_ideas', ideas, (i) => i.toMap());
  }

  Future<void> _uploadInBatches<T>(
    String collection,
    List<T> items,
    Map<String, dynamic> Function(T) toMap,
  ) async {
    const batchSize = 500;
    final totalBatches = (items.length / batchSize).ceil();

    for (var i = 0; i < totalBatches; i++) {
      final start = i * batchSize;
      final end = (i + 1) * batchSize;
      final batch = items.sublist(start, end > items.length ? items.length : end);

      final writeBatch = _firestore.batch();

      for (final item in batch) {
        final docRef = _firestore.collection(collection).doc();
        final data = toMap(item);
        data['id'] = docRef.id; // Добавляем ID документа
        writeBatch.set(docRef, data);
      }

      try {
        await writeBatch.commit();
        print('✅ Загружен батч ${i + 1}/$totalBatches для $collection');
      } catch (e) {
        print('❌ Ошибка загрузки батча ${i + 1}: $e');
        // Повторная попытка
        await Future.delayed(const Duration(seconds: 2));
        try {
          await writeBatch.commit();
          print('✅ Повторная загрузка батча ${i + 1} успешна');
        } catch (e2) {
          print('❌ Повторная ошибка для батча ${i + 1}: $e2');
        }
      }
    }
  }

  Future<int> _getCollectionCount(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Ошибка подсчета документов в $collection: $e');
      return 0;
    }
  }

  Future<void> _printSampleData() async {
    print('\n📋 ПРИМЕРЫ ДАННЫХ:');

    try {
      // Пример специалиста
      final specialistSnapshot = await _firestore.collection('specialists').limit(1).get();

      if (specialistSnapshot.docs.isNotEmpty) {
        final specialist = specialistSnapshot.docs.first.data();
        print('\n👨‍💼 Пример специалиста:');
        print('  Имя: ${specialist['name']}');
        print('  Категория: ${specialist['category']}');
        print('  Город: ${specialist['location']}');
        print('  Рейтинг: ${specialist['rating']}');
      }

      // Пример идеи
      final ideaSnapshot = await _firestore.collection('event_ideas').limit(1).get();

      if (ideaSnapshot.docs.isNotEmpty) {
        final idea = ideaSnapshot.docs.first.data();
        print('\n💡 Пример идеи:');
        print('  Название: ${idea['title']}');
        print('  Категория: ${idea['category']}');
        print('  Лайки: ${idea['likesCount']}');
      }
    } catch (e) {
      print('❌ Ошибка получения примеров: $e');
    }
  }
}
