/// Справочник ролей специалистов
class SpecialistRoles {
  static const List<Map<String, String>> allRoles = [
    {'id': 'host', 'label': 'Ведущий'},
    {'id': 'dj', 'label': 'Диджей'},
    {'id': 'organizer', 'label': 'Организатор'},
    {'id': 'photographer', 'label': 'Фотограф'},
    {'id': 'videographer', 'label': 'Видеограф'},
    {'id': 'vocal', 'label': 'Вокалист'},
    {'id': 'animator', 'label': 'Аниматор'},
    {'id': 'decor', 'label': 'Декоратор'},
    {'id': 'florist', 'label': 'Флорист'},
    {'id': 'sound', 'label': 'Звукорежиссёр'},
    {'id': 'light', 'label': 'Световик'},
    {'id': 'group', 'label': 'Кавер-группа'},
    {'id': 'magician', 'label': 'Иллюзионист'},
    {'id': 'choreographer', 'label': 'Хореограф'},
    {'id': 'hostess', 'label': 'Хостес'},
    {'id': 'equipment', 'label': 'Аренда аппаратуры'},
    {'id': 'costumes', 'label': 'Аренда костюмов'},
    {'id': 'catering', 'label': 'Кейтеринг'},
    {'id': 'security', 'label': 'Охрана'},
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

