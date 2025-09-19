/// Утилиты для заглушек отсутствующих функций и методов
library stubs;

import 'package:flutter/material.dart';

/// Выбрасывает UnimplementedError для неподдерживаемых функций
Never unsupported(String name) => throw UnimplementedError(
      'Function/method "$name" is not yet implemented. '
      'This is a placeholder that needs to be implemented.',
    );

/// Возвращает fallback значение для функций, которые еще не готовы
T notReady<T>(String name, T fallback) {
  // TODO: Implement $name
  return fallback;
}

/// Заглушка для JSON сериализации
Map<String, dynamic> _$BadgeStatsFromJson(Map<String, dynamic> json) {
  // TODO: Implement proper JSON serialization for BadgeStats
  return json;
}

/// Заглушка для JSON сериализации
Map<String, dynamic> _$BadgeLeaderboardEntryFromJson(
  Map<String, dynamic> json,
) {
  // TODO: Implement proper JSON serialization for BadgeLeaderboardEntry
  return json;
}

/// Заглушка для JSON сериализации
Map<String, dynamic> _$SpecialistSearchFiltersFromJson(
  Map<String, dynamic> json,
) {
  // TODO: Implement proper JSON serialization for SpecialistSearchFilters
  return json;
}

/// Заглушка для JSON сериализации
Map<String, dynamic> _$SpecialistSearchResultFromJson(
  Map<String, dynamic> json,
) {
  // TODO: Implement proper JSON serialization for SpecialistSearchResult
  return json;
}

/// Заглушка для JSON сериализации
Map<String, dynamic> _$SearchStateFromJson(Map<String, dynamic> json) {
  // TODO: Implement proper JSON serialization for SearchState
  return json;
}

/// Заглушка для JSON сериализации
Map<String, dynamic> _$SecurityPasswordStrengthFromJson(
  Map<String, dynamic> json,
) {
  // TODO: Implement proper JSON serialization for SecurityPasswordStrength
  return json;
}

/// Заглушка для методов, которые еще не реализованы
class MethodStubs {
  /// Заглушка для updateTitle
  static void updateTitle(String title) {
    // TODO: Implement updateTitle method
  }

  /// Заглушка для updateDescription
  static void updateDescription(String description) {
    // TODO: Implement updateDescription method
  }

  /// Заглушка для updateDate
  static void updateDate(DateTime date) {
    // TODO: Implement updateDate method
  }

  /// Заглушка для updateEndDate
  static void updateEndDate(DateTime endDate) {
    // TODO: Implement updateEndDate method
  }

  /// Заглушка для updateLocation
  static void updateLocation(String location) {
    // TODO: Implement updateLocation method
  }

  /// Заглушка для updatePrice
  static void updatePrice(double price) {
    // TODO: Implement updatePrice method
  }

  /// Заглушка для updateCategory
  static void updateCategory(String category) {
    // TODO: Implement updateCategory method
  }

  /// Заглушка для updateMaxParticipants
  static void updateMaxParticipants(int maxParticipants) {
    // TODO: Implement updateMaxParticipants method
  }

  /// Заглушка для updateContactInfo
  static void updateContactInfo(String contactInfo) {
    // TODO: Implement updateContactInfo method
  }

  /// Заглушка для updateRequirements
  static void updateRequirements(String requirements) {
    // TODO: Implement updateRequirements method
  }

  /// Заглушка для updateIsPublic
  static void updateIsPublic(bool isPublic) {
    // TODO: Implement updateIsPublic method
  }

  /// Заглушка для createEvent
  static Future<String> createEvent() async {
    // TODO: Implement createEvent method
    return 'stub-event-id';
  }

  /// Заглушка для createBooking
  static Future<String> createBooking() async {
    // TODO: Implement createBooking method
    return 'stub-booking-id';
  }

  /// Заглушка для getChat
  static Future<dynamic> getChat(String chatId) async {
    // TODO: Implement getChat method
    return null;
  }

  /// Заглушка для sendMessage
  static Future<void> sendMessage(String chatId, String message) async {
    // TODO: Implement sendMessage method
  }

  /// Заглушка для _buildStatItem
  static Widget _buildStatItem(String title, String value) {
    // TODO: Implement _buildStatItem method
    return Text('$title: $value');
  }

  /// Заглушка для ResponsiveScaffold
  static Widget ResponsiveScaffold({
    required Widget body,
    String? title,
    List<Widget>? actions,
  }) {
    // TODO: Implement ResponsiveScaffold method
    return Scaffold(
      appBar:
          AppBar(title: title != null ? Text(title) : null, actions: actions),
      body: body,
    );
  }
}

/// Заглушка для IEventData
class IEventData {
  IEventData();
}

/// Заглушка для ICalendar
class ICalendar {
  ICalendar();
}
