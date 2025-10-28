import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/user.dart';

/// Расширенная модель профиля пользователя с дополнительными полями
class UserProfileEnhanced {
  const UserProfileEnhanced({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.phone,
    this.city,
    this.region,
    this.website,
    this.socialLinks,
    this.videoPresentation,
    this.isProAccount = false,
    this.isVerified = false,
    this.visibilitySettings,
    this.privacySettings,
    this.notificationSettings,
    this.appearanceSettings,
    this.securitySettings,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
    this.role,
  });

  /// Создать из документа Firestore
  factory UserProfileEnhanced.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserProfileEnhanced.fromMap(data, doc.id);
  }

  /// Создать из Map
  factory UserProfileEnhanced.fromMap(Map<String, dynamic> data, [String? id]) {
    return UserProfileEnhanced(
      id: id ?? data['id'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      username: data['username'],
      bio: data['bio'],
      avatarUrl: data['avatarUrl'],
      coverUrl: data['coverUrl'],
      phone: data['phone'],
      city: data['city'],
      region: data['region'],
      website: data['website'],
      socialLinks: data['socialLinks'] != null
          ? (data['socialLinks'] as List)
              .map((e) => SocialLink.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
      videoPresentation: data['videoPresentation'],
      isProAccount: data['isProAccount'] as bool? ?? false,
      isVerified: data['isVerified'] as bool? ?? false,
      visibilitySettings: data['visibilitySettings'] != null
          ? ProfileVisibilitySettings.fromMap(
              data['visibilitySettings'] as Map<String, dynamic>,)
          : null,
      privacySettings: data['privacySettings'] != null
          ? PrivacySettings.fromMap(
              data['privacySettings'] as Map<String, dynamic>,)
          : null,
      notificationSettings: data['notificationSettings'] != null
          ? NotificationSettings.fromMap(
              data['notificationSettings'] as Map<String, dynamic>,)
          : null,
      appearanceSettings: data['appearanceSettings'] != null
          ? AppearanceSettings.fromMap(
              data['appearanceSettings'] as Map<String, dynamic>,)
          : null,
      securitySettings: data['securitySettings'] != null
          ? SecuritySettings.fromMap(
              data['securitySettings'] as Map<String, dynamic>,)
          : null,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      isActive: data['isActive'] as bool? ?? true,
      role: data['role'] != null
          ? UserRole.values.firstWhere(
              (e) => e.name == data['role'],
              orElse: () => UserRole.customer,
            )
          : null,
    );
  }

  final String id;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? username; // @username
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final String? phone;
  final String? city;
  final String? region;
  final String? website;
  final List<SocialLink>? socialLinks;
  final String? videoPresentation; // URL видео-презентации
  final bool isProAccount;
  final bool isVerified;
  final ProfileVisibilitySettings? visibilitySettings;
  final PrivacySettings? privacySettings;
  final NotificationSettings? notificationSettings;
  final AppearanceSettings? appearanceSettings;
  final SecuritySettings? securitySettings;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final UserRole? role;

  /// Конвертировать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'phone': phone,
      'city': city,
      'region': region,
      'website': website,
      'socialLinks': socialLinks?.map((e) => e.toMap()).toList(),
      'videoPresentation': videoPresentation,
      'isProAccount': isProAccount,
      'isVerified': isVerified,
      'visibilitySettings': visibilitySettings?.toMap(),
      'privacySettings': privacySettings?.toMap(),
      'notificationSettings': notificationSettings?.toMap(),
      'appearanceSettings': appearanceSettings?.toMap(),
      'securitySettings': securitySettings?.toMap(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
      'role': role?.name,
    };
  }

  /// Копировать с изменениями
  UserProfileEnhanced copyWith({
    String? id,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    String? phone,
    String? city,
    String? region,
    String? website,
    List<SocialLink>? socialLinks,
    String? videoPresentation,
    bool? isProAccount,
    bool? isVerified,
    ProfileVisibilitySettings? visibilitySettings,
    PrivacySettings? privacySettings,
    NotificationSettings? notificationSettings,
    AppearanceSettings? appearanceSettings,
    SecuritySettings? securitySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
    UserRole? role,
  }) {
    return UserProfileEnhanced(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      region: region ?? this.region,
      website: website ?? this.website,
      socialLinks: socialLinks ?? this.socialLinks,
      videoPresentation: videoPresentation ?? this.videoPresentation,
      isProAccount: isProAccount ?? this.isProAccount,
      isVerified: isVerified ?? this.isVerified,
      visibilitySettings: visibilitySettings ?? this.visibilitySettings,
      privacySettings: privacySettings ?? this.privacySettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      appearanceSettings: appearanceSettings ?? this.appearanceSettings,
      securitySettings: securitySettings ?? this.securitySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
    );
  }

  /// Получить полное имя
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return displayName ?? email.split('@').first;
  }

  /// Получить отображаемое имя
  String get displayNameOrEmail => displayName ?? email.split('@').first;

  /// Парсинг временных полей
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'UserProfileEnhanced(id: $id, email: $email, displayName: $displayName)';
}

/// Социальные ссылки
class SocialLink {
  const SocialLink({
    required this.platform,
    required this.url,
    this.isVisible = true,
  });

  factory SocialLink.fromMap(Map<String, dynamic> data) {
    return SocialLink(
      platform: data['platform'] ?? '',
      url: data['url'] ?? '',
      isVisible: data['isVisible'] as bool? ?? true,
    );
  }

  final String platform; // 'instagram', 'telegram', 'vk', 'youtube', etc.
  final String url;
  final bool isVisible;

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'url': url,
      'isVisible': isVisible,
    };
  }
}

/// Настройки видимости профиля
class ProfileVisibilitySettings {
  const ProfileVisibilitySettings({
    this.profileVisibility = ProfileVisibility.all,
    this.showPhone = false,
    this.showEmail = false,
    this.showCity = true,
    this.showActivity = true,
    this.showFollowers = true,
    this.showFollowing = true,
  });

  factory ProfileVisibilitySettings.fromMap(Map<String, dynamic> data) {
    return ProfileVisibilitySettings(
      profileVisibility: ProfileVisibility.values.firstWhere(
        (e) => e.name == data['profileVisibility'],
        orElse: () => ProfileVisibility.all,
      ),
      showPhone: data['showPhone'] as bool? ?? false,
      showEmail: data['showEmail'] as bool? ?? false,
      showCity: data['showCity'] as bool? ?? true,
      showActivity: data['showActivity'] as bool? ?? true,
      showFollowers: data['showFollowers'] as bool? ?? true,
      showFollowing: data['showFollowing'] as bool? ?? true,
    );
  }

  final ProfileVisibility profileVisibility;
  final bool showPhone;
  final bool showEmail;
  final bool showCity;
  final bool showActivity;
  final bool showFollowers;
  final bool showFollowing;

  Map<String, dynamic> toMap() {
    return {
      'profileVisibility': profileVisibility.name,
      'showPhone': showPhone,
      'showEmail': showEmail,
      'showCity': showCity,
      'showActivity': showActivity,
      'showFollowers': showFollowers,
      'showFollowing': showFollowing,
    };
  }
}

/// Уровни видимости профиля
enum ProfileVisibility {
  all, // Все пользователи
  registered, // Только зарегистрированные
  followers, // Только подписчики
  private, // Приватный
}

/// Настройки конфиденциальности
class PrivacySettings {
  const PrivacySettings({
    this.whoCanMessage = MessagePermission.registered,
    this.whoCanComment = CommentPermission.registered,
    this.whoCanMention = MentionPermission.registered,
    this.hideFromSearch = false,
    this.hideStoriesFrom = const [],
    this.closeFriendsOnly = false,
    this.archiveStories = false,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> data) {
    return PrivacySettings(
      whoCanMessage: MessagePermission.values.firstWhere(
        (e) => e.name == data['whoCanMessage'],
        orElse: () => MessagePermission.registered,
      ),
      whoCanComment: CommentPermission.values.firstWhere(
        (e) => e.name == data['whoCanComment'],
        orElse: () => CommentPermission.registered,
      ),
      whoCanMention: MentionPermission.values.firstWhere(
        (e) => e.name == data['whoCanMention'],
        orElse: () => MentionPermission.registered,
      ),
      hideFromSearch: data['hideFromSearch'] as bool? ?? false,
      hideStoriesFrom: List<String>.from(data['hideStoriesFrom'] ?? []),
      closeFriendsOnly: data['closeFriendsOnly'] as bool? ?? false,
      archiveStories: data['archiveStories'] as bool? ?? false,
    );
  }

  final MessagePermission whoCanMessage;
  final CommentPermission whoCanComment;
  final MentionPermission whoCanMention;
  final bool hideFromSearch;
  final List<String> hideStoriesFrom; // ID пользователей
  final bool closeFriendsOnly;
  final bool archiveStories;

  Map<String, dynamic> toMap() {
    return {
      'whoCanMessage': whoCanMessage.name,
      'whoCanComment': whoCanComment.name,
      'whoCanMention': whoCanMention.name,
      'hideFromSearch': hideFromSearch,
      'hideStoriesFrom': hideStoriesFrom,
      'closeFriendsOnly': closeFriendsOnly,
      'archiveStories': archiveStories,
    };
  }
}

/// Разрешения на сообщения
enum MessagePermission {
  all,
  registered,
  followers,
  none,
}

/// Разрешения на комментарии
enum CommentPermission {
  all,
  registered,
  followers,
  none,
}

/// Разрешения на упоминания
enum MentionPermission {
  all,
  registered,
  followers,
  none,
}

/// Настройки уведомлений
class NotificationSettings {
  const NotificationSettings({
    this.likes = true,
    this.comments = true,
    this.follows = true,
    this.messages = true,
    this.requests = true,
    this.recommendations = true,
    this.system = true,
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.soundEnabled = true,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> data) {
    return NotificationSettings(
      likes: data['likes'] as bool? ?? true,
      comments: data['comments'] as bool? ?? true,
      follows: data['follows'] as bool? ?? true,
      messages: data['messages'] as bool? ?? true,
      requests: data['requests'] as bool? ?? true,
      recommendations: data['recommendations'] as bool? ?? true,
      system: data['system'] as bool? ?? true,
      pushEnabled: data['pushEnabled'] as bool? ?? true,
      emailEnabled: data['emailEnabled'] as bool? ?? true,
      quietHoursEnabled: data['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: data['quietHoursStart'],
      quietHoursEnd: data['quietHoursEnd'],
      soundEnabled: data['soundEnabled'] as bool? ?? true,
    );
  }

  final bool likes;
  final bool comments;
  final bool follows;
  final bool messages;
  final bool requests;
  final bool recommendations;
  final bool system;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool quietHoursEnabled;
  final String? quietHoursStart; // "22:00"
  final String? quietHoursEnd; // "08:00"
  final bool soundEnabled;

  Map<String, dynamic> toMap() {
    return {
      'likes': likes,
      'comments': comments,
      'follows': follows,
      'messages': messages,
      'requests': requests,
      'recommendations': recommendations,
      'system': system,
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'soundEnabled': soundEnabled,
    };
  }
}

/// Настройки внешнего вида
class AppearanceSettings {
  const AppearanceSettings({
    this.theme = AppTheme.system,
    this.fontSize = FontSize.medium,
    this.tabPosition = TabPosition.bottom,
    this.animationsEnabled = true,
    this.customBackground,
  }); // URL кастомного фона

  factory AppearanceSettings.fromMap(Map<String, dynamic> data) {
    return AppearanceSettings(
      theme: AppTheme.values.firstWhere(
        (e) => e.name == data['theme'],
        orElse: () => AppTheme.system,
      ),
      fontSize: FontSize.values.firstWhere(
        (e) => e.name == data['fontSize'],
        orElse: () => FontSize.medium,
      ),
      tabPosition: TabPosition.values.firstWhere(
        (e) => e.name == data['tabPosition'],
        orElse: () => TabPosition.bottom,
      ),
      animationsEnabled: data['animationsEnabled'] as bool? ?? true,
      customBackground: data['customBackground'],
    );
  }

  final AppTheme theme;
  final FontSize fontSize;
  final TabPosition tabPosition;
  final bool animationsEnabled;
  final String? customBackground;

  Map<String, dynamic> toMap() {
    return {
      'theme': theme.name,
      'fontSize': fontSize.name,
      'tabPosition': tabPosition.name,
      'animationsEnabled': animationsEnabled,
      'customBackground': customBackground,
    };
  }
}

/// Темы приложения
enum AppTheme {
  light,
  dark,
  system,
}

/// Размеры шрифта
enum FontSize {
  small,
  medium,
  large,
  extraLarge,
}

/// Позиция вкладок
enum TabPosition {
  bottom,
  side,
}

/// Настройки безопасности
class SecuritySettings {
  const SecuritySettings({
    this.twoFactorEnabled = false,
    this.twoFactorMethod = TwoFactorMethod.sms,
    this.sessions = const [],
    this.loginHistory = const [],
    this.blockedRegions = const [],
    this.suspiciousLoginAlerts = true,
  });

  factory SecuritySettings.fromMap(Map<String, dynamic> data) {
    return SecuritySettings(
      twoFactorEnabled: data['twoFactorEnabled'] as bool? ?? false,
      twoFactorMethod: TwoFactorMethod.values.firstWhere(
        (e) => e.name == data['twoFactorMethod'],
        orElse: () => TwoFactorMethod.sms,
      ),
      sessions: data['sessions'] != null
          ? (data['sessions'] as List)
              .map((e) => UserSession.fromMap(e as Map<String, dynamic>))
              .toList()
          : [],
      loginHistory: data['loginHistory'] != null
          ? (data['loginHistory'] as List)
              .map((e) => LoginHistory.fromMap(e as Map<String, dynamic>))
              .toList()
          : [],
      blockedRegions: List<String>.from(data['blockedRegions'] ?? []),
      suspiciousLoginAlerts: data['suspiciousLoginAlerts'] as bool? ?? true,
    );
  }

  final bool twoFactorEnabled;
  final TwoFactorMethod twoFactorMethod;
  final List<UserSession> sessions;
  final List<LoginHistory> loginHistory;
  final List<String> blockedRegions;
  final bool suspiciousLoginAlerts;

  Map<String, dynamic> toMap() {
    return {
      'twoFactorEnabled': twoFactorEnabled,
      'twoFactorMethod': twoFactorMethod.name,
      'sessions': sessions.map((e) => e.toMap()).toList(),
      'loginHistory': loginHistory.map((e) => e.toMap()).toList(),
      'blockedRegions': blockedRegions,
      'suspiciousLoginAlerts': suspiciousLoginAlerts,
    };
  }
}

/// Методы двухфакторной аутентификации
enum TwoFactorMethod {
  sms,
  email,
  authenticator,
}

/// Сессия пользователя
class UserSession {
  const UserSession({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.location,
    required this.lastActive,
    required this.isActive,
  });

  factory UserSession.fromMap(Map<String, dynamic> data) {
    return UserSession(
      id: data['id'] ?? '',
      deviceName: data['deviceName'] ?? '',
      deviceType: data['deviceType'] ?? '',
      ipAddress: data['ipAddress'] ?? '',
      location: data['location'] ?? '',
      lastActive: DateTime.tryParse(data['lastActive'] ?? '') ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  final String id;
  final String deviceName;
  final String deviceType;
  final String ipAddress;
  final String location;
  final DateTime lastActive;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'ipAddress': ipAddress,
      'location': location,
      'lastActive': lastActive.toIso8601String(),
      'isActive': isActive,
    };
  }
}

/// История входов
class LoginHistory {
  const LoginHistory({
    required this.timestamp,
    required this.ipAddress,
    required this.location,
    required this.deviceName,
    required this.success,
    this.failureReason,
  });

  factory LoginHistory.fromMap(Map<String, dynamic> data) {
    return LoginHistory(
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      ipAddress: data['ipAddress'] ?? '',
      location: data['location'] ?? '',
      deviceName: data['deviceName'] ?? '',
      success: data['success'] as bool? ?? false,
      failureReason: data['failureReason'],
    );
  }

  final DateTime timestamp;
  final String ipAddress;
  final String location;
  final String deviceName;
  final bool success;
  final String? failureReason;

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'location': location,
      'deviceName': deviceName,
      'success': success,
      'failureReason': failureReason,
    };
  }
}
