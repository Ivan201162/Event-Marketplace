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
    // Если это hex-цвет
    if (colorName.startsWith('#')) {
      try {
        return Color(int.parse(colorName.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        return Colors.grey;
      }
    }
    
    // Если это название цвета
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
}
