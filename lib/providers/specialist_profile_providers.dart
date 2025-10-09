import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_statistics.dart';
import '../models/portfolio_item.dart';
import '../models/social_link.dart';
import '../services/specialist_profile_service.dart';

/// Провайдер сервиса профиля специалиста
final specialistProfileServiceProvider = Provider<SpecialistProfileService>((ref) {
  return SpecialistProfileService();
});

/// Провайдер статистики профиля специалиста
final specialistProfileStatisticsProvider = FutureProvider.family<ProfileStatistics, String>((ref, specialistId) async {
  final service = ref.read(specialistProfileServiceProvider);
  return await service.getProfileStatistics(specialistId);
});

/// Провайдер портфолио специалиста
final specialistPortfolioProvider = FutureProvider.family<List<PortfolioItem>, String>((ref, specialistId) async {
  final service = ref.read(specialistProfileServiceProvider);
  return await service.getPortfolio(specialistId);
});

/// Провайдер социальных ссылок специалиста
final specialistSocialLinksProvider = FutureProvider.family<List<SocialLink>, String>((ref, specialistId) async {
  final service = ref.read(specialistProfileServiceProvider);
  return await service.getSocialLinks(specialistId);
});

/// Провайдер закреплённых постов специалиста
final specialistPinnedPostsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, specialistId) async {
  final service = ref.read(specialistProfileServiceProvider);
  return await service.getPinnedPosts(specialistId);
});

/// Провайдер для обновления статистики профиля
final updateProfileStatisticsProvider = FutureProvider.family<void, UpdateStatisticsParams>((ref, params) async {
  final service = ref.read(specialistProfileServiceProvider);
  await service.updateProfileStatistics(params.specialistId, params.statistics);
});

/// Провайдер для увеличения просмотров
final incrementViewsProvider = FutureProvider.family<void, String>((ref, specialistId) async {
  final service = ref.read(specialistProfileServiceProvider);
  await service.incrementViews(specialistId);
});

/// Провайдер для добавления элемента портфолио
final addPortfolioItemProvider = FutureProvider.family<void, AddPortfolioItemParams>((ref, params) async {
  final service = ref.read(specialistProfileServiceProvider);
  await service.addPortfolioItem(params.specialistId, params.item);
});

/// Провайдер для удаления элемента портфолио
final removePortfolioItemProvider = FutureProvider.family<void, RemovePortfolioItemParams>((ref, params) async {
  final service = ref.read(specialistProfileServiceProvider);
  await service.removePortfolioItem(params.specialistId, params.itemId);
});

/// Провайдер для добавления социальной ссылки
final addSocialLinkProvider = FutureProvider.family<void, AddSocialLinkParams>((ref, params) async {
  final service = ref.read(specialistProfileServiceProvider);
  await service.addSocialLink(params.specialistId, params.link);
});

/// Провайдер для удаления социальной ссылки
final removeSocialLinkProvider = FutureProvider.family<void, RemoveSocialLinkParams>((ref, params) async {
  final service = ref.read(specialistProfileServiceProvider);
  await service.removeSocialLink(params.specialistId, params.linkId);
});

/// Провайдер для закрепления поста
final pinPostProvider = FutureProvider.family<void, PinPostParams>((ref, params) async {
  final service = ref.read(specialistProfileServiceProvider);
  await service.pinPost(params.specialistId, params.postId);
});

/// Провайдер для открепления поста
final unpinPostProvider = FutureProvider.family<void, UnpinPostParams>((ref, params) async {
  final service = ref.read(specialistProfileServiceProvider);
  await service.unpinPost(params.specialistId, params.pinnedPostId);
});

/// Провайдер для обновления статуса онлайн
final updateOnlineStatusProvider = FutureProvider.family<void, UpdateOnlineStatusParams>((ref, params) async {
  final service = ref.read(specialistProfileServiceProvider);
  await service.updateOnlineStatus(params.specialistId, params.isOnline);
});

/// Провайдер для шаринга профиля
final shareProfileProvider = FutureProvider.family<String, String>((ref, specialistId) async {
  final service = ref.read(specialistProfileServiceProvider);
  return await service.shareProfile(specialistId);
});

/// Параметры для обновления статистики
class UpdateStatisticsParams {
  final String specialistId;
  final ProfileStatistics statistics;

  const UpdateStatisticsParams({
    required this.specialistId,
    required this.statistics,
  });
}

/// Параметры для добавления элемента портфолио
class AddPortfolioItemParams {
  final String specialistId;
  final PortfolioItem item;

  const AddPortfolioItemParams({
    required this.specialistId,
    required this.item,
  });
}

/// Параметры для удаления элемента портфолио
class RemovePortfolioItemParams {
  final String specialistId;
  final String itemId;

  const RemovePortfolioItemParams({
    required this.specialistId,
    required this.itemId,
  });
}

/// Параметры для добавления социальной ссылки
class AddSocialLinkParams {
  final String specialistId;
  final SocialLink link;

  const AddSocialLinkParams({
    required this.specialistId,
    required this.link,
  });
}

/// Параметры для удаления социальной ссылки
class RemoveSocialLinkParams {
  final String specialistId;
  final String linkId;

  const RemoveSocialLinkParams({
    required this.specialistId,
    required this.linkId,
  });
}

/// Параметры для закрепления поста
class PinPostParams {
  final String specialistId;
  final String postId;

  const PinPostParams({
    required this.specialistId,
    required this.postId,
  });
}

/// Параметры для открепления поста
class UnpinPostParams {
  final String specialistId;
  final String pinnedPostId;

  const UnpinPostParams({
    required this.specialistId,
    required this.pinnedPostId,
  });
}

/// Параметры для обновления статуса онлайн
class UpdateOnlineStatusParams {
  final String specialistId;
  final bool isOnline;

  const UpdateOnlineStatusParams({
    required this.specialistId,
    required this.isOnline,
  });
}

