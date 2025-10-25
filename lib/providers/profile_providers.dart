import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';

/// Провайдер сервиса профиля
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// Провайдер состояния профиля
final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile>>((ref) {
  return ProfileNotifier(ref.read(profileServiceProvider));
});

/// Notifier для управления состоянием профиля
class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final ProfileService _profileService;

  ProfileNotifier(this._profileService) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      state = const AsyncValue.loading();
      final profile = await _profileService.getCurrentUserProfile();
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _profileService.updateProfile(profile);
      state = AsyncValue.data(profile);
    } catch (error) {
      // Обработка ошибки обновления профиля
      rethrow;
    }
  }

  Future<void> toggleFollow() async {
    try {
      await _profileService.toggleFollow();
      // Обновить состояние профиля
      if (state.hasValue) {
        final currentProfile = state.value!;
        final updatedProfile = currentProfile.copyWith(
          isFollowing: !currentProfile.isFollowing,
          followersCount: currentProfile.isFollowing 
              ? currentProfile.followersCount - 1 
              : currentProfile.followersCount + 1,
        );
        state = AsyncValue.data(updatedProfile);
      }
    } catch (error) {
      // Обработка ошибки подписки
    }
  }

  Future<void> uploadAvatar(String imagePath) async {
    try {
      final avatarUrl = await _profileService.uploadAvatar(imagePath);
      if (state.hasValue) {
        final currentProfile = state.value!;
        final updatedProfile = currentProfile.copyWith(avatarUrl: avatarUrl);
        state = AsyncValue.data(updatedProfile);
      }
    } catch (error) {
      // Обработка ошибки загрузки аватара
      rethrow;
    }
  }

  Future<void> uploadCover(String imagePath) async {
    try {
      final coverUrl = await _profileService.uploadCover(imagePath);
      if (state.hasValue) {
        final currentProfile = state.value!;
        final updatedProfile = currentProfile.copyWith(coverUrl: coverUrl);
        state = AsyncValue.data(updatedProfile);
      }
    } catch (error) {
      // Обработка ошибки загрузки обложки
      rethrow;
    }
  }
}