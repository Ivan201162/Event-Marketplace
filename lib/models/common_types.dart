/// Категории специалистов
enum SpecialistCategory {
  host, // Ведущий
  photographer, // Фотограф
  animator, // Аниматор
  dj, // Диджей
  decorator, // Оформитель
  catering, // Кейтеринг
  cleaning, // Клининг
  equipment, // Аренда свет/звук
  clothing, // Платья/костюмы
  fireShow, // Фаер-шоу
  fireworks, // Салюты
  lightShow, // Световые шоу
  florist, // Флорист
  coverBand, // Кавер-группа
  teamBuilding, // Тимбилдинг
  videographer, // Видеограф
  makeup, // Визажист
  musician, // Музыкант
  caterer, // Кейтеринг
  security, // Охрана
  technician, // Техник
  other, // Другое
}

/// SpecialistCategory extensions
extension SpecialistCategoryExtension on SpecialistCategory {
  /// Get display name for category
  String get displayName {
    switch (this) {
      case SpecialistCategory.host:
        return 'Ведущий';
      case SpecialistCategory.photographer:
        return 'Фотограф';
      case SpecialistCategory.animator:
        return 'Аниматор';
      case SpecialistCategory.dj:
        return 'Диджей';
      case SpecialistCategory.decorator:
        return 'Оформитель';
      case SpecialistCategory.catering:
        return 'Кейтеринг';
      case SpecialistCategory.cleaning:
        return 'Клининг';
      case SpecialistCategory.equipment:
        return 'Оборудование';
      case SpecialistCategory.clothing:
        return 'Одежда';
      case SpecialistCategory.fireShow:
        return 'Фаер-шоу';
      case SpecialistCategory.fireworks:
        return 'Салюты';
      case SpecialistCategory.lightShow:
        return 'Световое шоу';
      case SpecialistCategory.florist:
        return 'Флорист';
      case SpecialistCategory.coverBand:
        return 'Кавер-группа';
      case SpecialistCategory.teamBuilding:
        return 'Тимбилдинг';
      case SpecialistCategory.videographer:
        return 'Видеограф';
      case SpecialistCategory.makeup:
        return 'Визажист';
      case SpecialistCategory.musician:
        return 'Музыкант';
      case SpecialistCategory.caterer:
        return 'Кейтеринг';
      case SpecialistCategory.security:
        return 'Охрана';
      case SpecialistCategory.technician:
        return 'Техник';
      case SpecialistCategory.other:
        return 'Другое';
    }
  }

  /// Get all category values
  static List<SpecialistCategory> get values => SpecialistCategory.values;
}

/// Уровни опыта специалистов
enum ExperienceLevel {
  beginner, // Начинающий
  intermediate, // Средний
  advanced, // Продвинутый
  expert, // Эксперт
}

/// Статусы платежей
enum PaymentStatus {
  pending, // Ожидает
  processing, // Обрабатывается
  completed, // Завершен
  failed, // Неудачный
  cancelled, // Отменен
  refunded, // Возвращен
}

/// Статусы заявок
enum RequestStatus {
  pending, // Ожидает
  accepted, // Принята
  rejected, // Отклонена
  completed, // Завершена
  cancelled, // Отменена
}

/// Статусы бронирований
enum BookingStatus {
  pending, // Ожидает подтверждения
  confirmed, // Подтверждено
  inProgress, // В процессе
  completed, // Завершено
  cancelled, // Отменено
}

/// Типы уведомлений
enum NotificationType {
  booking, // Бронирование
  message, // Сообщение
  review, // Отзыв
  payment, // Платеж
  system, // Системное
  promotion, // Акция
}

/// Расширения для enum'ов
extension SpecialistCategoryExtension on SpecialistCategory {
  String get displayName {
    switch (this) {
      case SpecialistCategory.host:
        return 'Ведущий';
      case SpecialistCategory.photographer:
        return 'Фотограф';
      case SpecialistCategory.animator:
        return 'Аниматор';
      case SpecialistCategory.dj:
        return 'Диджей';
      case SpecialistCategory.decorator:
        return 'Оформитель';
      case SpecialistCategory.catering:
        return 'Кейтеринг';
      case SpecialistCategory.cleaning:
        return 'Клининг';
      case SpecialistCategory.equipment:
        return 'Аренда свет/звук';
      case SpecialistCategory.clothing:
        return 'Платья/костюмы';
      case SpecialistCategory.fireShow:
        return 'Фаер-шоу';
      case SpecialistCategory.fireworks:
        return 'Салюты';
      case SpecialistCategory.lightShow:
        return 'Световые шоу';
      case SpecialistCategory.florist:
        return 'Флорист';
      case SpecialistCategory.coverBand:
        return 'Кавер-группа';
      case SpecialistCategory.teamBuilding:
        return 'Тимбилдинг';
      case SpecialistCategory.videographer:
        return 'Видеограф';
      case SpecialistCategory.makeup:
        return 'Визажист';
      case SpecialistCategory.musician:
        return 'Музыкант';
      case SpecialistCategory.caterer:
        return 'Кейтеринг';
      case SpecialistCategory.security:
        return 'Охрана';
      case SpecialistCategory.technician:
        return 'Техник';
      case SpecialistCategory.other:
        return 'Другое';
    }
  }

  String get emoji {
    switch (this) {
      case SpecialistCategory.host:
        return '🎤';
      case SpecialistCategory.photographer:
        return '📸';
      case SpecialistCategory.animator:
        return '🎭';
      case SpecialistCategory.dj:
        return '🎧';
      case SpecialistCategory.decorator:
        return '🎨';
      case SpecialistCategory.catering:
        return '🍽️';
      case SpecialistCategory.cleaning:
        return '🧹';
      case SpecialistCategory.equipment:
        return '🔊';
      case SpecialistCategory.clothing:
        return '👗';
      case SpecialistCategory.fireShow:
        return '🔥';
      case SpecialistCategory.fireworks:
        return '🎆';
      case SpecialistCategory.lightShow:
        return '💡';
      case SpecialistCategory.florist:
        return '🌸';
      case SpecialistCategory.coverBand:
        return '🎵';
      case SpecialistCategory.teamBuilding:
        return '🤝';
      case SpecialistCategory.videographer:
        return '🎬';
      case SpecialistCategory.makeup:
        return '💄';
      case SpecialistCategory.musician:
        return '🎼';
      case SpecialistCategory.caterer:
        return '🍽️';
      case SpecialistCategory.security:
        return '🛡️';
      case SpecialistCategory.technician:
        return '🔧';
      case SpecialistCategory.other:
        return '📋';
    }
  }
}

extension ExperienceLevelExtension on ExperienceLevel {
  String get displayName {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Начинающий';
      case ExperienceLevel.intermediate:
        return 'Средний';
      case ExperienceLevel.advanced:
        return 'Продвинутый';
      case ExperienceLevel.expert:
        return 'Эксперт';
    }
  }

  int get minYears {
    switch (this) {
      case ExperienceLevel.beginner:
        return 0;
      case ExperienceLevel.intermediate:
        return 2;
      case ExperienceLevel.advanced:
        return 5;
      case ExperienceLevel.expert:
        return 10;
    }
  }
}
