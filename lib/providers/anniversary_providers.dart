import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user.dart';
import '../services/anniversary_service.dart';
import 'firestore_providers.dart';

part 'anniversary_providers.g.dart';

/// Провайдер сервиса годовщин
@riverpod
AnniversaryService anniversaryService(AnniversaryServiceRef ref) => AnniversaryService();

/// Провайдер информации о годовщине пользователя
@riverpod
Future<Map<String, dynamic>> userAnniversaryInfo(
  UserAnniversaryInfoRef ref,
  String userId,
) async {
  final service = ref.read(anniversaryServiceProvider);

  // Получаем пользователя из Firestore
  final userDoc = await ref.read(firestoreProvider).collection('users').doc(userId).get();
  if (!userDoc.exists) {
    return {
      'hasWeddingDate': false,
      'message': 'Пользователь не найден',
    };
  }

  final user = AppUser.fromDocument(userDoc);
  return service.getAnniversaryInfo(user);
}

/// Провайдер для обновления настроек годовщин
@riverpod
class AnniversarySettingsNotifier extends _$AnniversarySettingsNotifier {
  @override
  FutureOr<void> build() => null;

  /// Обновить настройки напоминаний о годовщинах
  Future<void> updateSettings({
    required String userId,
    required bool enabled,
    DateTime? weddingDate,
    String? partnerName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(anniversaryServiceProvider);
      await service.updateAnniversarySettings(
        userId: userId,
        enabled: enabled,
        weddingDate: weddingDate,
        partnerName: partnerName,
      );

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Проверить и отправить напоминания о годовщинах
  Future<void> checkAndSendReminders() async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(anniversaryServiceProvider);
      await service.checkAndSendAnniversaryReminders();

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Провайдер пользователей с годовщинами в ближайшие дни
@riverpod
Future<List<AppUser>> upcomingAnniversaries(
  UpcomingAnniversariesRef ref,
  int daysAhead,
) async {
  final service = ref.read(anniversaryServiceProvider);
  final now = DateTime.now();
  final endDate = now.add(Duration(days: daysAhead));

  return service.getUsersWithAnniversariesInPeriod(
    startDate: now,
    endDate: endDate,
  );
}
