// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anniversary_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Провайдер сервиса годовщин

@ProviderFor(anniversaryService)
const anniversaryServiceProvider = AnniversaryServiceProvider._();

/// Провайдер сервиса годовщин

final class AnniversaryServiceProvider extends $FunctionalProvider<
    AnniversaryService,
    AnniversaryService,
    AnniversaryService> with $Provider<AnniversaryService> {
  /// Провайдер сервиса годовщин
  const AnniversaryServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'anniversaryServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$anniversaryServiceHash();

  @$internal
  @override
  $ProviderElement<AnniversaryService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnniversaryService create(Ref ref) {
    return anniversaryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnniversaryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnniversaryService>(value),
    );
  }
}

String _$anniversaryServiceHash() =>
    r'c4a7c62bc754e4d09ace669e62dcca753250aae6';

/// Провайдер информации о годовщине пользователя

@ProviderFor(userAnniversaryInfo)
const userAnniversaryInfoProvider = UserAnniversaryInfoFamily._();

/// Провайдер информации о годовщине пользователя

final class UserAnniversaryInfoProvider extends $FunctionalProvider<
        AsyncValue<Map<String, dynamic>>,
        Map<String, dynamic>,
        FutureOr<Map<String, dynamic>>>
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  /// Провайдер информации о годовщине пользователя
  const UserAnniversaryInfoProvider._(
      {required UserAnniversaryInfoFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'userAnniversaryInfoProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userAnniversaryInfoHash();

  @override
  String toString() {
    return r'userAnniversaryInfoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    final argument = this.argument as String;
    return userAnniversaryInfo(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserAnniversaryInfoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userAnniversaryInfoHash() =>
    r'630eaedc887cf3bab9af4469eef4ecce90bf948e';

/// Провайдер информации о годовщине пользователя

final class UserAnniversaryInfoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>>, String> {
  const UserAnniversaryInfoFamily._()
      : super(
          retry: null,
          name: r'userAnniversaryInfoProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Провайдер информации о годовщине пользователя

  UserAnniversaryInfoProvider call(
    String userId,
  ) =>
      UserAnniversaryInfoProvider._(argument: userId, from: this);

  @override
  String toString() => r'userAnniversaryInfoProvider';
}

/// Провайдер для обновления настроек годовщин

@ProviderFor(AnniversarySettingsNotifier)
const anniversarySettingsProvider = AnniversarySettingsNotifierProvider._();

/// Провайдер для обновления настроек годовщин
final class AnniversarySettingsNotifierProvider
    extends $AsyncNotifierProvider<AnniversarySettingsNotifier, void> {
  /// Провайдер для обновления настроек годовщин
  const AnniversarySettingsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'anniversarySettingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$anniversarySettingsNotifierHash();

  @$internal
  @override
  AnniversarySettingsNotifier create() => AnniversarySettingsNotifier();
}

String _$anniversarySettingsNotifierHash() =>
    r'f1ba5c10f4d215b14709cea3ec17fd90a8a5126a';

/// Провайдер для обновления настроек годовщин

abstract class _$AnniversarySettingsNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<void>, void>,
        AsyncValue<void>,
        Object?,
        Object?>;
    element.handleValue(ref, null);
  }
}

/// Провайдер пользователей с годовщинами в ближайшие дни

@ProviderFor(upcomingAnniversaries)
const upcomingAnniversariesProvider = UpcomingAnniversariesFamily._();

/// Провайдер пользователей с годовщинами в ближайшие дни

final class UpcomingAnniversariesProvider extends $FunctionalProvider<
        AsyncValue<List<AppUser>>, List<AppUser>, FutureOr<List<AppUser>>>
    with $FutureModifier<List<AppUser>>, $FutureProvider<List<AppUser>> {
  /// Провайдер пользователей с годовщинами в ближайшие дни
  const UpcomingAnniversariesProvider._(
      {required UpcomingAnniversariesFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'upcomingAnniversariesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$upcomingAnniversariesHash();

  @override
  String toString() {
    return r'upcomingAnniversariesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AppUser>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppUser>> create(Ref ref) {
    final argument = this.argument as int;
    return upcomingAnniversaries(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingAnniversariesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$upcomingAnniversariesHash() =>
    r'b189262e778937705c6c31e81f9bf9dcaba1679c';

/// Провайдер пользователей с годовщинами в ближайшие дни

final class UpcomingAnniversariesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AppUser>>, int> {
  const UpcomingAnniversariesFamily._()
      : super(
          retry: null,
          name: r'upcomingAnniversariesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Провайдер пользователей с годовщинами в ближайшие дни

  UpcomingAnniversariesProvider call(
    int daysAhead,
  ) =>
      UpcomingAnniversariesProvider._(argument: daysAhead, from: this);

  @override
  String toString() => r'upcomingAnniversariesProvider';
}
