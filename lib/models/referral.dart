import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель реферала
class Referral {
  const Referral({
    required this.id,
    required this.inviterId,
    required this.invitedUserId,
    required this.timestamp,
    required this.bonus,
    this.isCompleted = false,
    this.invitedUserName,
    this.invitedUserEmail,
    this.completedAt,
  });

  /// Создание из Firestore документа
  factory Referral.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Referral(
      id: doc.id,
      inviterId: data['inviterId'] ?? '',
      invitedUserId: data['invitedUserId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      bonus: data['bonus'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      invitedUserName: data['invitedUserName'],
      invitedUserEmail: data['invitedUserEmail'],
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }
  final String id;
  final String inviterId;
  final String invitedUserId;
  final DateTime timestamp;
  final int bonus;
  final bool isCompleted;
  final String? invitedUserName;
  final String? invitedUserEmail;
  final DateTime? completedAt;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'inviterId': inviterId,
        'invitedUserId': invitedUserId,
        'timestamp': Timestamp.fromDate(timestamp),
        'bonus': bonus,
        'isCompleted': isCompleted,
        'invitedUserName': invitedUserName,
        'invitedUserEmail': invitedUserEmail,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };

  /// Копирование с изменениями
  Referral copyWith({
    String? id,
    String? inviterId,
    String? invitedUserId,
    DateTime? timestamp,
    int? bonus,
    bool? isCompleted,
    String? invitedUserName,
    String? invitedUserEmail,
    DateTime? completedAt,
  }) =>
      Referral(
        id: id ?? this.id,
        inviterId: inviterId ?? this.inviterId,
        invitedUserId: invitedUserId ?? this.invitedUserId,
        timestamp: timestamp ?? this.timestamp,
        bonus: bonus ?? this.bonus,
        isCompleted: isCompleted ?? this.isCompleted,
        invitedUserName: invitedUserName ?? this.invitedUserName,
        invitedUserEmail: invitedUserEmail ?? this.invitedUserEmail,
        completedAt: completedAt ?? this.completedAt,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Referral && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Referral(id: $id, inviter: $inviterId, invited: $invitedUserId, bonus: $bonus)';
}

/// Модель партнёрской программы
class PartnerProgram {
  const PartnerProgram({
    required this.userId,
    required this.referralCode,
    required this.totalReferrals,
    required this.completedReferrals,
    required this.totalBonus,
    required this.status,
    required this.joinedAt,
    required this.lastActivityAt,
  });

  /// Создание из Firestore документа
  factory PartnerProgram.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PartnerProgram(
      userId: doc.id,
      referralCode: data['referralCode'] ?? '',
      totalReferrals: data['totalReferrals'] ?? 0,
      completedReferrals: data['completedReferrals'] ?? 0,
      totalBonus: data['totalBonus'] ?? 0,
      status: PartnerStatus.values.firstWhere(
        (status) => status.value == data['status'],
        orElse: () => PartnerStatus.bronze,
      ),
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp).toDate(),
    );
  }
  final String userId;
  final String referralCode;
  final int totalReferrals;
  final int completedReferrals;
  final int totalBonus;
  final PartnerStatus status;
  final DateTime joinedAt;
  final DateTime lastActivityAt;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'referralCode': referralCode,
        'totalReferrals': totalReferrals,
        'completedReferrals': completedReferrals,
        'totalBonus': totalBonus,
        'status': status.value,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'lastActivityAt': Timestamp.fromDate(lastActivityAt),
      };

  /// Получить реферальную ссылку
  String get referralLink =>
      'https://eventmarketplace.app/invite/$referralCode';

  /// Проверить, можно ли получить следующий статус
  bool get canUpgrade {
    switch (status) {
      case PartnerStatus.bronze:
        return completedReferrals >= 5;
      case PartnerStatus.silver:
        return completedReferrals >= 10;
      case PartnerStatus.gold:
        return completedReferrals >= 20;
      case PartnerStatus.platinum:
        return false; // Максимальный статус
    }
  }

  /// Получить следующий статус
  PartnerStatus? get nextStatus {
    switch (status) {
      case PartnerStatus.bronze:
        return PartnerStatus.silver;
      case PartnerStatus.silver:
        return PartnerStatus.gold;
      case PartnerStatus.gold:
        return PartnerStatus.platinum;
      case PartnerStatus.platinum:
        return null;
    }
  }

  /// Получить прогресс до следующего статуса
  double get progressToNextStatus {
    if (!canUpgrade) return 0;

    switch (status) {
      case PartnerStatus.bronze:
        return completedReferrals / 5;
      case PartnerStatus.silver:
        return completedReferrals / 10;
      case PartnerStatus.gold:
        return completedReferrals / 20;
      case PartnerStatus.platinum:
        return 1;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartnerProgram && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'PartnerProgram(userId: $userId, status: $status, referrals: $completedReferrals)';
}

/// Статусы партнёрской программы
enum PartnerStatus {
  bronze('bronze', 'Бронзовый партнёр', 0, 5),
  silver('silver', 'Серебряный партнёр', 5, 10),
  gold('gold', 'Золотой партнёр', 10, 20),
  platinum('platinum', 'Платиновый партнёр', 20, 999);

  const PartnerStatus(
      this.value, this.displayName, this.minReferrals, this.maxReferrals,);

  final String value;
  final String displayName;
  final int minReferrals;
  final int maxReferrals;

  /// Получить цвет статуса
  Color get color {
    switch (this) {
      case PartnerStatus.bronze:
        return const Color(0xFFCD7F32); // Бронзовый
      case PartnerStatus.silver:
        return const Color(0xFFC0C0C0); // Серебряный
      case PartnerStatus.gold:
        return const Color(0xFFFFD700); // Золотой
      case PartnerStatus.platinum:
        return const Color(0xFFE5E4E2); // Платиновый
    }
  }

  /// Получить иконку статуса
  IconData get icon {
    switch (this) {
      case PartnerStatus.bronze:
        return Icons.emoji_events;
      case PartnerStatus.silver:
        return Icons.emoji_events;
      case PartnerStatus.gold:
        return Icons.emoji_events;
      case PartnerStatus.platinum:
        return Icons.diamond;
    }
  }
}

/// Модель бонуса
class Bonus {
  const Bonus({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    required this.earnedAt,
    this.isUsed = false,
    this.usedAt,
    this.usedFor,
  });

  /// Создание из Firestore документа
  factory Bonus.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Bonus(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: data['amount'] ?? 0,
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      earnedAt: (data['earnedAt'] as Timestamp).toDate(),
      isUsed: data['isUsed'] ?? false,
      usedAt: data['usedAt'] != null
          ? (data['usedAt'] as Timestamp).toDate()
          : null,
      usedFor: data['usedFor'],
    );
  }
  final String id;
  final String userId;
  final int amount;
  final String type;
  final String description;
  final DateTime earnedAt;
  final bool isUsed;
  final DateTime? usedAt;
  final String? usedFor;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'amount': amount,
        'type': type,
        'description': description,
        'earnedAt': Timestamp.fromDate(earnedAt),
        'isUsed': isUsed,
        'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
        'usedFor': usedFor,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bonus && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Bonus(id: $id, amount: $amount, type: $type)';
}

/// Типы бонусов
enum BonusType {
  referral('referral', 'За приглашение'),
  registration('registration', 'За регистрацию'),
  firstBooking('firstBooking', 'За первое бронирование'),
  review('review', 'За отзыв'),
  milestone('milestone', 'За достижение');

  const BonusType(this.value, this.displayName);
  final String value;
  final String displayName;
}
