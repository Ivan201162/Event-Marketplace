import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/share_service.dart';
import '../core/feature_flags.dart';

/// Провайдер для проверки доступности шаринга
final shareAvailableProvider = Provider<bool>((ref) {
  return FeatureFlags.shareEnabled;
});

/// Провайдер для получения информации о шаринге
final shareInfoProvider = Provider<Map<String, dynamic>>((ref) {
  return ShareService.shareInfo;
});

/// Провайдер для получения поддерживаемых платформ
final supportedSharePlatformsProvider = Provider<List<String>>((ref) {
  return ShareService.supportedPlatforms;
});

/// Провайдер для шаринга события
final shareEventProvider =
    FutureProvider.family<bool, String>((ref, eventId) async {
  // Здесь можно добавить логику получения события по ID
  // Пока возвращаем false, так как нужен объект Event
  return false;
});

/// Провайдер для шаринга профиля
final shareProfileProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  // Здесь можно добавить логику получения пользователя по ID
  // Пока возвращаем false, так как нужен объект AppUser
  return false;
});

/// Провайдер для шаринга бронирования
final shareBookingProvider =
    FutureProvider.family<bool, String>((ref, bookingId) async {
  // Здесь можно добавить логику получения бронирования по ID
  // Пока возвращаем false, так как нужен объект Booking
  return false;
});

/// Провайдер для шаринга текста
final shareTextProvider =
    FutureProvider.family<bool, String>((ref, text) async {
  return await ShareService.shareText(text);
});

/// Провайдер для шаринга ссылки
final shareLinkProvider = FutureProvider.family<bool,
    ({String url, String? title, String? description})>((ref, params) async {
  return await ShareService.shareLink(params.url,
      title: params.title, description: params.description);
});

/// Провайдер для шаринга файла
final shareFileProvider = FutureProvider.family<bool,
    ({String filePath, String? text, String? subject})>((ref, params) async {
  return await ShareService.shareFile(params.filePath,
      text: params.text, subject: params.subject);
});

/// Провайдер для шаринга нескольких файлов
final shareFilesProvider = FutureProvider.family<
    bool,
    ({
      List<String> filePaths,
      String? text,
      String? subject
    })>((ref, params) async {
  return await ShareService.shareFiles(params.filePaths,
      text: params.text, subject: params.subject);
});

/// Провайдер для открытия ссылки
final openLinkProvider = FutureProvider.family<bool, String>((ref, url) async {
  return await ShareService.openLink(url);
});

/// Провайдер для открытия email
final openEmailProvider = FutureProvider.family<bool,
    ({String email, String? subject, String? body})>((ref, params) async {
  return await ShareService.openEmail(params.email,
      subject: params.subject, body: params.body);
});

/// Провайдер для открытия телефона
final openPhoneProvider =
    FutureProvider.family<bool, String>((ref, phone) async {
  return await ShareService.openPhone(phone);
});

/// Провайдер для открытия SMS
final openSmsProvider =
    FutureProvider.family<bool, ({String phone, String? message})>(
        (ref, params) async {
  return await ShareService.openSms(params.phone, message: params.message);
});

/// Нотификатор для статуса шаринга
class ShareStatusNotifier extends Notifier<String> {
  @override
  String build() => 'ready';

  void setStatus(String status) {
    state = status;
  }

  void reset() {
    state = 'ready';
  }
}

/// Провайдер для статуса шаринга
final shareStatusProvider = NotifierProvider<ShareStatusNotifier, String>(() {
  return ShareStatusNotifier();
});

/// Нотификатор для прогресса шаринга
class ShareProgressNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void setProgress(double progress) {
    state = progress;
  }

  void reset() {
    state = 0.0;
  }
}

/// Провайдер для отслеживания прогресса шаринга
final shareProgressProvider =
    NotifierProvider<ShareProgressNotifier, double>(() {
  return ShareProgressNotifier();
});

/// Нотификатор для ошибок шаринга
class ShareErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? error) {
    state = error;
  }

  void clearError() {
    state = null;
  }
}

/// Провайдер для последней ошибки шаринга
final shareErrorProvider = NotifierProvider<ShareErrorNotifier, String?>(() {
  return ShareErrorNotifier();
});

/// Нотификатор для истории шаринга
class ShareHistoryNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void addToHistory(Map<String, dynamic> item) {
    state = [...state, item];
  }

  void clearHistory() {
    state = [];
  }
}

/// Провайдер для истории шаринга
final shareHistoryProvider =
    NotifierProvider<ShareHistoryNotifier, List<Map<String, dynamic>>>(() {
  return ShareHistoryNotifier();
});

/// Провайдер для настроек шаринга
final shareSettingsProvider =
    NotifierProvider<ShareSettingsNotifier, ShareSettings>(() {
  return ShareSettingsNotifier();
});

/// Настройки шаринга
class ShareSettings {
  final bool includeAppName;
  final bool includeAppLink;
  final bool includeUserInfo;
  final bool includeEventDetails;
  final bool includeBookingDetails;
  final String defaultMessage;
  final bool autoCopyToClipboard;
  final bool showShareDialog;

  const ShareSettings({
    this.includeAppName = true,
    this.includeAppLink = true,
    this.includeUserInfo = true,
    this.includeEventDetails = true,
    this.includeBookingDetails = true,
    this.defaultMessage = 'Поделитесь этим с друзьями!',
    this.autoCopyToClipboard = false,
    this.showShareDialog = true,
  });

  ShareSettings copyWith({
    bool? includeAppName,
    bool? includeAppLink,
    bool? includeUserInfo,
    bool? includeEventDetails,
    bool? includeBookingDetails,
    String? defaultMessage,
    bool? autoCopyToClipboard,
    bool? showShareDialog,
  }) {
    return ShareSettings(
      includeAppName: includeAppName ?? this.includeAppName,
      includeAppLink: includeAppLink ?? this.includeAppLink,
      includeUserInfo: includeUserInfo ?? this.includeUserInfo,
      includeEventDetails: includeEventDetails ?? this.includeEventDetails,
      includeBookingDetails:
          includeBookingDetails ?? this.includeBookingDetails,
      defaultMessage: defaultMessage ?? this.defaultMessage,
      autoCopyToClipboard: autoCopyToClipboard ?? this.autoCopyToClipboard,
      showShareDialog: showShareDialog ?? this.showShareDialog,
    );
  }
}

/// Нотификатор для настроек шаринга
class ShareSettingsNotifier extends Notifier<ShareSettings> {
  @override
  ShareSettings build() => const ShareSettings();

  void updateIncludeAppName(bool value) {
    state = state.copyWith(includeAppName: value);
  }

  void updateIncludeAppLink(bool value) {
    state = state.copyWith(includeAppLink: value);
  }

  void updateIncludeUserInfo(bool value) {
    state = state.copyWith(includeUserInfo: value);
  }

  void updateIncludeEventDetails(bool value) {
    state = state.copyWith(includeEventDetails: value);
  }

  void updateIncludeBookingDetails(bool value) {
    state = state.copyWith(includeBookingDetails: value);
  }

  void updateDefaultMessage(String message) {
    state = state.copyWith(defaultMessage: message);
  }

  void updateAutoCopyToClipboard(bool value) {
    state = state.copyWith(autoCopyToClipboard: value);
  }

  void updateShowShareDialog(bool value) {
    state = state.copyWith(showShareDialog: value);
  }

  void resetToDefaults() {
    state = const ShareSettings();
  }
}

/// Нотификатор для статистики шаринга
class ShareStatsNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {
        'totalShares': 0,
        'successfulShares': 0,
        'failedShares': 0,
        'eventsShared': 0,
        'profilesShared': 0,
        'bookingsShared': 0,
        'textsShared': 0,
        'linksShared': 0,
        'filesShared': 0,
      };

  void incrementStat(String key) {
    state = {...state, key: (state[key] ?? 0) + 1};
  }

  void resetStats() {
    state = {
      'totalShares': 0,
      'successfulShares': 0,
      'failedShares': 0,
      'eventsShared': 0,
      'profilesShared': 0,
      'bookingsShared': 0,
      'textsShared': 0,
      'linksShared': 0,
      'filesShared': 0,
    };
  }
}

/// Провайдер для статистики шаринга
final shareStatsProvider =
    NotifierProvider<ShareStatsNotifier, Map<String, int>>(() {
  return ShareStatsNotifier();
});

/// Нотификатор для последнего шаринга
class LastShareNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setLastShare(Map<String, dynamic>? share) {
    state = share;
  }

  void clearLastShare() {
    state = null;
  }
}

/// Провайдер для последнего шаринга
final lastShareProvider =
    NotifierProvider<LastShareNotifier, Map<String, dynamic>?>(() {
  return LastShareNotifier();
});

/// Нотификатор для активных шарингов
class ActiveSharesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void addShare(String shareId) {
    state = {...state, shareId};
  }

  void removeShare(String shareId) {
    state = state.where((id) => id != shareId).toSet();
  }

  void clearShares() {
    state = {};
  }
}

/// Провайдер для активных шарингов
final activeSharesProvider =
    NotifierProvider<ActiveSharesNotifier, Set<String>>(() {
  return ActiveSharesNotifier();
});

/// Нотификатор для очереди шаринга
class ShareQueueNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void addToQueue(Map<String, dynamic> share) {
    state = [...state, share];
  }

  void removeFromQueue(String shareId) {
    state = state.where((share) => share['id'] != shareId).toList();
  }

  void clearQueue() {
    state = [];
  }
}

/// Провайдер для очереди шаринга
final shareQueueProvider =
    NotifierProvider<ShareQueueNotifier, List<Map<String, dynamic>>>(() {
  return ShareQueueNotifier();
});

/// Провайдер для проверки, идет ли шаринг
final isSharingProvider = Provider<bool>((ref) {
  final activeShares = ref.watch(activeSharesProvider);
  return activeShares.isNotEmpty;
});

/// Провайдер для получения количества элементов в очереди
final shareQueueLengthProvider = Provider<int>((ref) {
  final queue = ref.watch(shareQueueProvider);
  return queue.length;
});

/// Провайдер для получения следующего элемента в очереди
final nextShareItemProvider = Provider<Map<String, dynamic>?>((ref) {
  final queue = ref.watch(shareQueueProvider);
  return queue.isNotEmpty ? queue.first : null;
});

/// Провайдер для проверки, можно ли добавить в очередь
final canAddToShareQueueProvider = Provider<bool>((ref) {
  final queueLength = ref.watch(shareQueueLengthProvider);
  return queueLength < 10;
});

/// Провайдер для проверки доступности конкретного типа шаринга
final canShareProvider = Provider.family<bool, String>((ref, type) {
  final isAvailable = ref.watch(shareAvailableProvider);

  switch (type) {
    case 'event':
    case 'profile':
    case 'booking':
    case 'text':
    case 'link':
    case 'file':
      return isAvailable;
    default:
      return false;
  }
});

/// Провайдер для получения рекомендуемого способа шаринга
final recommendedShareMethodProvider = Provider<String>((ref) {
  final supportedPlatforms = ref.watch(supportedSharePlatformsProvider);

  if (supportedPlatforms.contains('Web Share API')) {
    return 'Web Share API';
  } else if (supportedPlatforms.contains('Android Share')) {
    return 'Android Share';
  } else if (supportedPlatforms.contains('iOS Share')) {
    return 'iOS Share';
  } else {
    return 'System Share';
  }
});

/// Провайдер для получения иконки шаринга
final shareIconProvider = Provider<String>((ref) {
  final supportedPlatforms = ref.watch(supportedSharePlatformsProvider);

  if (supportedPlatforms.contains('WhatsApp')) {
    return 'whatsapp';
  } else if (supportedPlatforms.contains('Telegram')) {
    return 'telegram';
  } else if (supportedPlatforms.contains('Email')) {
    return 'email';
  } else {
    return 'share';
  }
});

/// Провайдер для получения цвета шаринга
final shareColorProvider = Provider<int>((ref) {
  final supportedPlatforms = ref.watch(supportedSharePlatformsProvider);

  if (supportedPlatforms.contains('WhatsApp')) {
    return 0xFF25D366; // WhatsApp green
  } else if (supportedPlatforms.contains('Telegram')) {
    return 0xFF0088CC; // Telegram blue
  } else if (supportedPlatforms.contains('Email')) {
    return 0xFFEA4335; // Gmail red
  } else {
    return 0xFF2196F3; // Material blue
  }
});
