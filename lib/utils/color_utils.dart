import 'package:flutter/material.dart';

/// Утилиты для работы с цветами
class ColorUtils {
  /// Преобразовать строку цвета в Color
  static Color getStatusColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Преобразовать строку цвета в Color для категорий
  static Color getCategoryColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'pink':
        return Colors.pink;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Получить цвет для категории (принимает Color)
  static Color getCategoryColorFromColor(Color color) {
    return color;
  }

  /// Получить иконку категории
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'фотография':
        return Icons.camera_alt;
      case 'видео':
        return Icons.videocam;
      case 'музыка':
        return Icons.music_note;
      case 'декор':
        return Icons.palette;
      case 'еда':
        return Icons.restaurant;
      case 'транспорт':
        return Icons.directions_car;
      default:
        return Icons.category;
    }
  }

  /// Преобразовать hex строку в Color
  static Color parseHexColor(String hexString) {
    // Убираем # если есть
    String hex = hexString.replaceAll('#', '');

    // Добавляем FF для альфа-канала если строка 6 символов
    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    // Проверяем что строка валидная
    if (hex.length != 8) {
      return Colors.grey; // Возвращаем серый по умолчанию
    }

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey; // Возвращаем серый по умолчанию при ошибке
    }
  }
}
