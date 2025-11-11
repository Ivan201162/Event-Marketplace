/// Справочник ролей специалистов (до 3 одновременно)
class SpecialistRoles {
  static const List<Map<String, String>> allRoles = [
    {'id': 'host', 'label': 'Ведущий'},
    {'id': 'dj', 'label': 'Диджей'},
    {'id': 'photographer', 'label': 'Фотограф'},
    {'id': 'videographer', 'label': 'Видеограф'},
    {'id': 'organizer', 'label': 'Организатор'},
    {'id': 'animator', 'label': 'Аниматор'},
    {'id': 'agency', 'label': 'Агентство'},
    {'id': 'equipment', 'label': 'Аренда аппаратуры'},
    {'id': 'costumes', 'label': 'Аренда костюмов'},
    {'id': 'dresses', 'label': 'Аренда платьев'},
    {'id': 'decor', 'label': 'Декоратор'},
    {'id': 'florist', 'label': 'Флорист'},
    {'id': 'pyrotechnics', 'label': 'Пиротехник'},
    {'id': 'sound', 'label': 'Звукорежиссёр/Свет'},
    {'id': 'musician', 'label': 'Музыкант/Вокалист'},
    {'id': 'group', 'label': 'Кавер-бэнд'},
    {'id': 'hostess', 'label': 'Хостес'},
    {'id': 'promo', 'label': 'Промо-персонал'},
    {'id': 'scriptwriter', 'label': 'Сценарист'},
    {'id': 'director', 'label': 'Постановщик'},
    {'id': 'coordinator', 'label': 'Координатор'},
    {'id': 'choreographer', 'label': 'Хореограф'},
    {'id': 'other', 'label': 'Другое'},
  ];

  /// Получить иконку по ID роли
  static String getIcon(String roleId) {
    switch (roleId) {
      case 'host':
        return '🎤';
      case 'dj':
        return '🎧';
      case 'organizer':
        return '👰';
      case 'photographer':
        return '📸';
      case 'videographer':
        return '🎥';
      case 'vocal':
        return '🎙';
      case 'animator':
        return '🎭';
      case 'decor':
        return '🎀';
      case 'florist':
        return '🌸';
      case 'sound':
        return '🔊';
      case 'light':
        return '💡';
      case 'group':
        return '🎸';
      case 'magician':
        return '🎩';
      case 'choreographer':
        return '💃';
      case 'hostess':
        return '👠';
      case 'equipment':
        return '🔌';
      case 'costumes':
        return '👔';
      case 'catering':
        return '🍽';
      case 'security':
        return '🛡';
      default:
        return '⭐';
    }
  }

  /// Получить роль по ID
  static Map<String, String>? getRoleById(String roleId) {
    try {
      return allRoles.firstWhere((role) => role['id'] == roleId);
    } catch (e) {
      return null;
    }
  }
}

