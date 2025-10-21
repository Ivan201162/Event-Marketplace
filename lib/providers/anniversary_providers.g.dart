// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anniversary_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$anniversaryServiceHash() => r'c4a7c62bc754e4d09ace669e62dcca753250aae6';

/// Провайдер сервиса годовщин
///
/// Copied from [anniversaryService].
@ProviderFor(anniversaryService)
final anniversaryServiceProvider = AutoDisposeProvider<AnniversaryService>.internal(
  anniversaryService,
  name: r'anniversaryServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$anniversaryServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnniversaryServiceRef = AutoDisposeProviderRef<AnniversaryService>;
String _$userAnniversaryInfoHash() => r'630eaedc887cf3bab9af4469eef4ecce90bf948e';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Провайдер информации о годовщине пользователя
///
/// Copied from [userAnniversaryInfo].
@ProviderFor(userAnniversaryInfo)
const userAnniversaryInfoProvider = UserAnniversaryInfoFamily();

/// Провайдер информации о годовщине пользователя
///
/// Copied from [userAnniversaryInfo].
class UserAnniversaryInfoFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// Провайдер информации о годовщине пользователя
  ///
  /// Copied from [userAnniversaryInfo].
  const UserAnniversaryInfoFamily();

  /// Провайдер информации о годовщине пользователя
  ///
  /// Copied from [userAnniversaryInfo].
  UserAnniversaryInfoProvider call(String userId) {
    return UserAnniversaryInfoProvider(userId);
  }

  @override
  UserAnniversaryInfoProvider getProviderOverride(covariant UserAnniversaryInfoProvider provider) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies => _allTransitiveDependencies;

  @override
  String? get name => r'userAnniversaryInfoProvider';
}

/// Провайдер информации о годовщине пользователя
///
/// Copied from [userAnniversaryInfo].
class UserAnniversaryInfoProvider extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// Провайдер информации о годовщине пользователя
  ///
  /// Copied from [userAnniversaryInfo].
  UserAnniversaryInfoProvider(String userId)
    : this._internal(
        (ref) => userAnniversaryInfo(ref as UserAnniversaryInfoRef, userId),
        from: userAnniversaryInfoProvider,
        name: r'userAnniversaryInfoProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userAnniversaryInfoHash,
        dependencies: UserAnniversaryInfoFamily._dependencies,
        allTransitiveDependencies: UserAnniversaryInfoFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserAnniversaryInfoProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(UserAnniversaryInfoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserAnniversaryInfoProvider._internal(
        (ref) => create(ref as UserAnniversaryInfoRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _UserAnniversaryInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserAnniversaryInfoProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserAnniversaryInfoRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserAnniversaryInfoProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with UserAnniversaryInfoRef {
  _UserAnniversaryInfoProviderElement(super.provider);

  @override
  String get userId => (origin as UserAnniversaryInfoProvider).userId;
}

String _$upcomingAnniversariesHash() => r'b189262e778937705c6c31e81f9bf9dcaba1679c';

/// Провайдер пользователей с годовщинами в ближайшие дни
///
/// Copied from [upcomingAnniversaries].
@ProviderFor(upcomingAnniversaries)
const upcomingAnniversariesProvider = UpcomingAnniversariesFamily();

/// Провайдер пользователей с годовщинами в ближайшие дни
///
/// Copied from [upcomingAnniversaries].
class UpcomingAnniversariesFamily extends Family<AsyncValue<List<AppUser>>> {
  /// Провайдер пользователей с годовщинами в ближайшие дни
  ///
  /// Copied from [upcomingAnniversaries].
  const UpcomingAnniversariesFamily();

  /// Провайдер пользователей с годовщинами в ближайшие дни
  ///
  /// Copied from [upcomingAnniversaries].
  UpcomingAnniversariesProvider call(int daysAhead) {
    return UpcomingAnniversariesProvider(daysAhead);
  }

  @override
  UpcomingAnniversariesProvider getProviderOverride(
    covariant UpcomingAnniversariesProvider provider,
  ) {
    return call(provider.daysAhead);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies => _allTransitiveDependencies;

  @override
  String? get name => r'upcomingAnniversariesProvider';
}

/// Провайдер пользователей с годовщинами в ближайшие дни
///
/// Copied from [upcomingAnniversaries].
class UpcomingAnniversariesProvider extends AutoDisposeFutureProvider<List<AppUser>> {
  /// Провайдер пользователей с годовщинами в ближайшие дни
  ///
  /// Copied from [upcomingAnniversaries].
  UpcomingAnniversariesProvider(int daysAhead)
    : this._internal(
        (ref) => upcomingAnniversaries(ref as UpcomingAnniversariesRef, daysAhead),
        from: upcomingAnniversariesProvider,
        name: r'upcomingAnniversariesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$upcomingAnniversariesHash,
        dependencies: UpcomingAnniversariesFamily._dependencies,
        allTransitiveDependencies: UpcomingAnniversariesFamily._allTransitiveDependencies,
        daysAhead: daysAhead,
      );

  UpcomingAnniversariesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.daysAhead,
  }) : super.internal();

  final int daysAhead;

  @override
  Override overrideWith(
    FutureOr<List<AppUser>> Function(UpcomingAnniversariesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpcomingAnniversariesProvider._internal(
        (ref) => create(ref as UpcomingAnniversariesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        daysAhead: daysAhead,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AppUser>> createElement() {
    return _UpcomingAnniversariesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingAnniversariesProvider && other.daysAhead == daysAhead;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, daysAhead.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpcomingAnniversariesRef on AutoDisposeFutureProviderRef<List<AppUser>> {
  /// The parameter `daysAhead` of this provider.
  int get daysAhead;
}

class _UpcomingAnniversariesProviderElement extends AutoDisposeFutureProviderElement<List<AppUser>>
    with UpcomingAnniversariesRef {
  _UpcomingAnniversariesProviderElement(super.provider);

  @override
  int get daysAhead => (origin as UpcomingAnniversariesProvider).daysAhead;
}

String _$anniversarySettingsNotifierHash() => r'f1ba5c10f4d215b14709cea3ec17fd90a8a5126a';

/// Провайдер для обновления настроек годовщин
///
/// Copied from [AnniversarySettingsNotifier].
@ProviderFor(AnniversarySettingsNotifier)
final anniversarySettingsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AnniversarySettingsNotifier, void>.internal(
      AnniversarySettingsNotifier.new,
      name: r'anniversarySettingsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anniversarySettingsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AnniversarySettingsNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
