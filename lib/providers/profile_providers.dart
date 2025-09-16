import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import '../models/customer_profile.dart';
import '../models/specialist_profile.dart';
import '../models/user.dart';

/// Провайдер сервиса профилей
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// Провайдер профиля заказчика
final customerProfileProvider =
    FutureProvider.family<CustomerProfile?, String>((ref, userId) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getCustomerProfile(userId);
});

/// Провайдер профиля специалиста
final specialistProfileProvider =
    FutureProvider.family<SpecialistProfile?, String>((ref, userId) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getSpecialistProfile(userId);
});

/// Провайдер профиля текущего пользователя
final currentUserProfileProvider =
    FutureProvider.family<dynamic, (String, UserRole)>((ref, params) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getUserProfile(params.$1, params.$2);
});

/// Провайдер специалистов по категории
final specialistsByCategoryProvider =
    FutureProvider.family<List<SpecialistProfile>, SpecialistCategory>(
        (ref, category) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getSpecialistsByCategory(category);
});

/// Провайдер топ специалистов
final topSpecialistsProvider =
    FutureProvider.family<List<SpecialistProfile>, int>((ref, limit) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getTopSpecialists(limit: limit);
});

/// Провайдер поиска специалистов
final searchSpecialistsProvider =
    FutureProvider.family<List<SpecialistProfile>, SearchSpecialistsParams>(
        (ref, params) {
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
    FutureProvider.family<Map<String, dynamic>, (String, UserRole)>(
        (ref, params) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getProfileStats(params.$1, params.$2);
});

/// Параметры поиска специалистов
class SearchSpecialistsParams {
  final String? query;
  final List<SpecialistCategory>? categories;
  final double? minRating;
  final double? maxHourlyRate;
  final String? location;

  const SearchSpecialistsParams({
    this.query,
    this.categories,
    this.minRating,
    this.maxHourlyRate,
    this.location,
  });

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
  int get hashCode {
    return Object.hash(query, categories, minRating, maxHourlyRate, location);
  }
}

/// Провайдер для управления состоянием редактирования профиля заказчика
final customerProfileEditProvider = StateNotifierProvider<
    CustomerProfileEditNotifier, CustomerProfileEditState>((ref) {
  return CustomerProfileEditNotifier(ref.read(profileServiceProvider));
});

/// Состояние редактирования профиля заказчика
class CustomerProfileEditState {
  final CustomerProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool isDirty;

  const CustomerProfileEditState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.isDirty = false,
  });

  CustomerProfileEditState copyWith({
    CustomerProfile? profile,
    bool? isLoading,
    String? errorMessage,
    bool? isDirty,
  }) {
    return CustomerProfileEditState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

/// Нотификатор для редактирования профиля заказчика
class CustomerProfileEditNotifier
    extends StateNotifier<CustomerProfileEditState> {
  final ProfileService _profileService;

  CustomerProfileEditNotifier(this._profileService)
      : super(const CustomerProfileEditState());

  /// Загрузить профиль
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

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
    MaritalStatus? maritalStatus,
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

    state = state.copyWith(isLoading: true, errorMessage: null);

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
    state = state.copyWith(isDirty: false, errorMessage: null);
  }
}

/// Провайдер для управления состоянием редактирования профиля специалиста
final specialistProfileEditProvider = StateNotifierProvider<
    SpecialistProfileEditNotifier, SpecialistProfileEditState>((ref) {
  return SpecialistProfileEditNotifier(ref.read(profileServiceProvider));
});

/// Состояние редактирования профиля специалиста
class SpecialistProfileEditState {
  final SpecialistProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool isDirty;

  const SpecialistProfileEditState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.isDirty = false,
  });

  SpecialistProfileEditState copyWith({
    SpecialistProfile? profile,
    bool? isLoading,
    String? errorMessage,
    bool? isDirty,
  }) {
    return SpecialistProfileEditState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

/// Нотификатор для редактирования профиля специалиста
class SpecialistProfileEditNotifier
    extends StateNotifier<SpecialistProfileEditState> {
  final ProfileService _profileService;

  SpecialistProfileEditNotifier(this._profileService)
      : super(const SpecialistProfileEditState());

  /// Загрузить профиль
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

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
    String? photoURL,
    String? bio,
    List<SpecialistCategory>? categories,
    int? experienceYears,
    double? hourlyRate,
    String? phoneNumber,
    String? location,
    Map<String, String>? socialLinks,
    List<String>? services,
    Map<String, dynamic>? workingHours,
  }) {
    if (state.profile == null) return;

    final updatedProfile = state.profile!.copyWith(
      photoURL: photoURL,
      bio: bio,
      categories: categories,
      experienceYears: experienceYears,
      hourlyRate: hourlyRate,
      phoneNumber: phoneNumber,
      location: location,
      socialLinks: socialLinks,
      services: services,
      workingHours: workingHours,
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

    final updatedPortfolio = List<PortfolioItem>.from(state.profile!.portfolio)
      ..add(item);
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

    final updatedPortfolio =
        state.profile!.portfolio.where((item) => item.id != itemId).toList();
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

    state = state.copyWith(isLoading: true, errorMessage: null);

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
    state = state.copyWith(isDirty: false, errorMessage: null);
  }
}
