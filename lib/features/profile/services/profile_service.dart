import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/user_repository.dart';
import '../../../models/user.dart';

/// Сервис для работы с профилем пользователя
class ProfileService {
  ProfileService(this._userRepository);
  final UserRepository _userRepository;

  /// Обеспечить наличие полей по умолчанию для пользователя
  Future<void> ensureUserDefaults(String uid) async {
    await _userRepository.ensureUserDefaults(uid);
  }

  /// Обновить город пользователя
  Future<bool> updateUserCity(String uid, String city) async {
    final updates = <String, dynamic>{
      'city': city.trim().isEmpty ? null : city.trim()
    };
    return _userRepository.updateUser(uid, updates);
  }

  /// Обновить регион пользователя
  Future<bool> updateUserRegion(String uid, String region) async {
    final updates = <String, dynamic>{
      'region': region.trim().isEmpty ? null : region.trim()
    };
    return _userRepository.updateUser(uid, updates);
  }

  /// Обновить аватар пользователя
  Future<bool> updateUserAvatar(String uid, String avatarUrl) async {
    final updates = <String, dynamic>{
      'avatarUrl': avatarUrl.trim().isEmpty ? null : avatarUrl.trim(),
    };
    return _userRepository.updateUser(uid, updates);
  }

  /// Получить пользователя по ID
  Future<AppUser?> getUser(String uid) async =>
      _userRepository.getUserById(uid);
}

/// Провайдер сервиса профиля
final profileServiceProvider = Provider<ProfileService>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return ProfileService(userRepository);
});

/// Провайдер для обновления города пользователя
final updateUserCityProvider =
    FutureProvider.family<bool, Map<String, String>>((
  ref,
  params,
) async {
  final service = ref.watch(profileServiceProvider);
  final uid = params['uid']!;
  final city = params['city']!;
  return service.updateUserCity(uid, city);
});

/// Провайдер для обновления региона пользователя
final updateUserRegionProvider =
    FutureProvider.family<bool, Map<String, String>>((
  ref,
  params,
) async {
  final service = ref.watch(profileServiceProvider);
  final uid = params['uid']!;
  final region = params['region']!;
  return service.updateUserRegion(uid, region);
});
