import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio_item.dart';
import '../models/profile_statistics.dart';
import '../models/social_link.dart';
import '../services/specialist_profile_service.dart';

/// Провайдер сервиса профиля специалиста
final specialistProfileServiceProvider = Provider<SpecialistProfileService>(
  (ref) => SpecialistProfileService(),
);

/// Провайдер статистики профиля
final profileStatisticsProvider = FutureProvider.family<ProfileStatistics, String>(
  (ref, specialistId) async {
    final service = ref.read(specialistProfileServiceProvider);
    return service.getProfileStatistics(specialistId);
  },
);

/// Провайдер портфолио
final portfolioProvider = FutureProvider.family<List<PortfolioItem>, String>(
  (ref, specialistId) async {
    final service = ref.read(specialistProfileServiceProvider);
    return service.getPortfolio(specialistId);
  },
);

/// Провайдер социальных ссылок
final socialLinksProvider = FutureProvider.family<List<SocialLink>, String>(
  (ref, specialistId) async {
    final service = ref.read(specialistProfileServiceProvider);
    return service.getSocialLinks(specialistId);
  },
);

/// Провайдер закреплённых постов
final pinnedPostsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, specialistId) async {
    final service = ref.read(specialistProfileServiceProvider);
    return service.getPinnedPosts(specialistId);
  },
);

/// Провайдер календаря занятости
final availabilityCalendarProvider =
    FutureProvider.family<List<Map<String, dynamic>>, AvailabilityParams>(
  (ref, params) async {
    final service = ref.read(specialistProfileServiceProvider);
    return service.getAvailabilityCalendar(
      params.specialistId,
      params.startDate,
      params.endDate,
    );
  },
);

/// Параметры для получения календаря занятости
class AvailabilityParams {
  const AvailabilityParams({
    required this.specialistId,
    required this.startDate,
    required this.endDate,
  });
  final String specialistId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AvailabilityParams &&
        other.specialistId == specialistId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(specialistId, startDate, endDate);
}
