import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_profile.dart';
import '../models/specialist_profile.dart';
import '../models/user.dart' as user_model;
import '../services/profile_service.dart';

/// Провайдер сервиса профилей
final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

/// Провайдер профиля заказчика
final customerProfileProvider = FutureProvider.family<CustomerProfile?, String>((ref, userId) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getCustomerProfile(userId);
});

/// Провайдер профиля специалиста
final specialistProfileProvider = FutureProvider.family<SpecialistProfile?, String>((ref, userId) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getSpecialistProfile(userId);
});

/// Провайдер профиля текущего пользователя
final currentUserProfileProvider =
    FutureProvider.family<dynamic, (String, user_model.UserRole)>((ref, params) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getUserProfile(params.$1, params.$2);
});

/// Провайдер специалистов по категории
final specialistsByCategoryProvider =
    FutureProvider.family<List<SpecialistProfile>, SpecialistCategory>((ref, category) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getSpecialistsByCategory(category);
});

/// Провайдер топ специалистов
final topSpecialistsProvider = FutureProvider.family<List<SpecialistProfile>, int>((ref, limit) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getTopSpecialists(limit: limit);
});

/// Провайдер поиска специалистов
final searchSpecialistsProvider =
    FutureProvider.family<List<SpecialistProfile>, SearchSpecialistsParams>((ref, params) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.searchSpecialists(
    query: params.query,
    categories: params.categories,
    minRating: params.minRating,
    maxHourlyRate: params.maxHourlyRate,
    location: params.location,
  );
});

/// Провайдер статистики профиля
final profileStatsProvider =
    FutureProvider.family<Map<String, dynamic>, (String, user_model.UserRole)>((ref, params) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getProfileStats(params.$1, params.$2);
});

/// Параметры поиска специалистов
class SearchSpecialistsParams {
  const SearchSpecialistsParams({
    this.query,
    this.categories,
    this.minRating,
    this.maxHourlyRate,
    this.location,
  });
  final String? query;
  final List<SpecialistCategory>? categories;
  final double? minRating;
  final double? maxHourlyRate;
  final String? location;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchSpecialistsParams &&
        other.query == query &&
        other.categories == categories &&
        other.minRating == minRating &&
        other.maxHourlyRate == maxHourlyRate &&
        other.location == location;
  }

  @override
  int get hashCode => Object.hash(query, categories, minRating, maxHourlyRate, location);
}

/// Провайдер для управления состоянием редактирования профиля заказчика
final customerProfileEditProvider =
    NotifierProvider<CustomerProfileEditNotifier, CustomerProfileEditState>(
  CustomerProfileEditNotifier.new,
);

/// Состояние редактирования профиля заказчика
class CustomerProfileEditState {
  const CustomerProfileEditState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.isDirty = false,
  });
  final CustomerProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool isDirty;

  CustomerProfileEditState copyWith({
    CustomerProfile? profile,
    bool? isLoading,
    String? errorMessage,
    bool? isDirty,
  }) =>
      CustomerProfileEditState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        isDirty: isDirty ?? this.isDirty,
      );
}

/// Нотификатор для редактирования профиля заказчика
class CustomerProfileEditNotifier extends Notifier<CustomerProfileEditState> {
  late final ProfileService _profileService;

  @override
  CustomerProfileEditState build() {
    _profileService = ref.read(profileServiceProvider);
    return const CustomerProfileEditState();
  }

  /// Загрузить профиль
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final profile = await _profileService.getCustomerProfile(userId);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Обновить поле профиля
  void updateField({
    String? photoURL,
    String? bio,
    user_model.MaritalStatus? maritalStatus,
    DateTime? weddingDate,
    DateTime? anniversaryDate,
    String? phoneNumber,
    String? location,
    List<String>? interests,
    List<String>? eventTypes,
  }) {
    if (state.profile == null) return;

    final updatedProfile = state.profile!.copyWith(
      photoURL: photoURL,
      bio: bio,
      maritalStatus: maritalStatus,
      weddingDate: weddingDate,
      anniversaryDate: anniversaryDate,
      phoneNumber: phoneNumber,
      location: location,
      interests: interests,
      eventTypes: eventTypes,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      profile: updatedProfile,
      isDirty: true,
    );
  }

  /// Сохранить профиль
  Future<void> saveProfile() async {
    if (state.profile == null) return;

    state = state.copyWith(isLoading: true);

    try {
      await _profileService.createOrUpdateCustomerProfile(state.profile!);
      state = state.copyWith(
        isLoading: false,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Сбросить изменения
  void reset() {
    state = state.copyWith(isDirty: false);
  }
}

/// Провайдер для управления состоянием редактирования профиля специалиста
final specialistProfileEditProvider =
    NotifierProvider<SpecialistProfileEditNotifier, SpecialistProfileEditState>(
  SpecialistProfileEditNotifier.new,
);

/// Состояние редактирования профиля специалиста
class SpecialistProfileEditState {
  const SpecialistProfileEditState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.isDirty = false,
  });
  final SpecialistProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool isDirty;

  SpecialistProfileEditState copyWith({
    SpecialistProfile? profile,
    bool? isLoading,
    String? errorMessage,
    bool? isDirty,
  }) =>
      SpecialistProfileEditState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        isDirty: isDirty ?? this.isDirty,
      );
}

/// Нотификатор для редактирования профиля специалиста
class SpecialistProfileEditNotifier extends Notifier<SpecialistProfileEditState> {
  late final ProfileService _profileService;

  @override
  SpecialistProfileEditState build() {
    _profileService = ref.read(profileServiceProvider);
    return const SpecialistProfileEditState();
  }

  /// Загрузить профиль
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final profile = await _profileService.getSpecialistProfile(userId);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Обновить поле профиля
  void updateField({
    String? name,
    String? photoURL,
    String? bio,
    List<SpecialistCategory>? categories,
    int? experienceYears,
    double? hourlyRate,
    String? phoneNumber,
    String? location,
    String? email,
    String? website,
    String? instagram,
    String? vk,
    String? telegram,
    String? whatsapp,
    String? skype,
    String? zoom,
    Map<String, String>? socialLinks,
    List<String>? services,
    Map<String, dynamic>? workingHours,
    bool? isAvailable,
    Map<String, dynamic>? availability,
    List<String>? languages,
    List<String>? equipment,
    bool? insurance,
    List<String>? licenses,
    List<String>? certifications,
    List<String>? awards,
    List<String>? testimonials,
  }) {
    if (state.profile == null) return;

    final updatedProfile = state.profile!.copyWith(
      name: name,
      photoURL: photoURL,
      bio: bio,
      categories: categories,
      experienceYears: experienceYears,
      hourlyRate: hourlyRate,
      phoneNumber: phoneNumber,
      location: location,
      email: email,
      website: website,
      instagram: instagram,
      vk: vk,
      telegram: telegram,
      whatsapp: whatsapp,
      skype: skype,
      zoom: zoom,
      socialLinks: socialLinks,
      services: services,
      workingHours: workingHours,
      isAvailable: isAvailable,
      availability: availability,
      languages: languages,
      equipment: equipment,
      insurance: insurance,
      licenses: licenses,
      certifications: certifications,
      awards: awards,
      testimonials: testimonials,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      profile: updatedProfile,
      isDirty: true,
    );
  }

  /// Добавить элемент портфолио
  void addPortfolioItem(PortfolioItem item) {
    if (state.profile == null) return;

    final updatedPortfolio = List<PortfolioItem>.from(state.profile!.portfolio)..add(item);
    final updatedProfile = state.profile!.copyWith(
      portfolio: updatedPortfolio,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      profile: updatedProfile,
      isDirty: true,
    );
  }

  /// Удалить элемент портфолио
  void removePortfolioItem(String itemId) {
    if (state.profile == null) return;

    final updatedPortfolio = state.profile!.portfolio.where((item) => item.id != itemId).toList();
    final updatedProfile = state.profile!.copyWith(
      portfolio: updatedPortfolio,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      profile: updatedProfile,
      isDirty: true,
    );
  }

  /// Сохранить профиль
  Future<void> saveProfile() async {
    if (state.profile == null) return;

    state = state.copyWith(isLoading: true);

    try {
      await _profileService.createOrUpdateSpecialistProfile(state.profile!);
      state = state.copyWith(
        isLoading: false,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Сбросить изменения
  void reset() {
    state = state.copyWith(isDirty: false);
  }
}
