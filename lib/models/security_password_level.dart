/// Уровни безопасности пароля
enum SecurityPasswordLevel {
  weak,
  fair,
  good,
  strong,
  veryStrong,
}

/// Расширение для SecurityPasswordLevel
extension SecurityPasswordLevelExtension on SecurityPasswordLevel {
  /// Получить цвет для уровня
  String get color {
    switch (this) {
      case SecurityPasswordLevel.weak:
        return '#FF5252'; // Красный
      case SecurityPasswordLevel.fair:
        return '#FF9800'; // Оранжевый
      case SecurityPasswordLevel.good:
        return '#FFC107'; // Желтый
      case SecurityPasswordLevel.strong:
        return '#4CAF50'; // Зеленый
      case SecurityPasswordLevel.veryStrong:
        return '#2196F3'; // Синий
    }
  }

  /// Получить текст для уровня
  String get text {
    switch (this) {
      case SecurityPasswordLevel.weak:
        return 'Слабый';
      case SecurityPasswordLevel.fair:
        return 'Удовлетворительный';
      case SecurityPasswordLevel.good:
        return 'Хороший';
      case SecurityPasswordLevel.strong:
        return 'Сильный';
      case SecurityPasswordLevel.veryStrong:
        return 'Очень сильный';
    }
  }

  /// Получить процент для уровня
  double get percentage {
    switch (this) {
      case SecurityPasswordLevel.weak:
        return 0.2;
      case SecurityPasswordLevel.fair:
        return 0.4;
      case SecurityPasswordLevel.good:
        return 0.6;
      case SecurityPasswordLevel.strong:
        return 0.8;
      case SecurityPasswordLevel.veryStrong:
        return 1.0;
    }
  }
}
